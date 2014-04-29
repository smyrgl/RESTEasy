//
//  TGNonPersistentServerTests.m
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import <XCTest/XCTest.h>
#import "TGRESTClient.h"
#import "TGTestFactory.h"
#import <Gizou/Gizou.h>

@interface TGCRUDTests : XCTestCase

@property (nonatomic, strong) TGRESTResource *testResource;

@end

@implementation TGCRUDTests

- (void)setUp
{
    [super setUp];
    self.testResource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:self.testResource];
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:self.testResource], @"The resource must have been successfully added to the server");
}

- (void)tearDown
{
    [[TGRESTServer sharedServer] stopServer];
    [super tearDown];
}

- (void)testGetAllObjectsWithNothing
{
    __weak typeof(self) weakSelf = self;
    __block NSArray *response;
    
    [[TGRESTClient sharedClient] GET:self.testResource.name
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The request must not have failed %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    XCTAssert(response.count == 0, @"The array should be empty");
}

- (void)testGetAllObjects
{
    [TGTestFactory createTestDataForResource:self.testResource count:100];
    
    __weak typeof(self) weakSelf = self;
    __block NSArray *response;
    
    [[TGRESTClient sharedClient] GET:self.testResource.name
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The request should not have failed %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(response.count == 100, @"The response must include 100 objects");
}

- (void)testGetSpecificObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @1]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The request must not have failed %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(response, @"There must be an object dictionary");
    XCTAssert([response[self.testResource.primaryKey] isEqualToNumber:@1], @"The primary key must equal 1");
}

- (void)testGetNonexistantObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @15]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 XCTFail(@"The response must not have been successful");
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(statusCode == 404, @"The failing status code must be a 404 not found error");
}

- (void)testGetDeletedObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                             parameters:nil
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    response = responseObject;
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    XCTFail(@"The delete request must not have failed %@", error);
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }];
    
    [self waitForTimeout:1];

    XCTAssert(statusCode == 204, @"Status code for a delete should be no content");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 9, @"There must be 9 resources after the delete process");
    
    __block NSUInteger getDeletedStatusCode;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 XCTFail(@"Getting the already deleted object should not be successful");
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 getDeletedStatusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }];
    
    [self waitForTimeout:1];
    XCTAssert(getDeletedStatusCode == 410, @"The status code for the response to get a deleted object must be 410 gone");
}

- (void)testCreateObject
{
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:self.testResource];
    
    [[TGRESTClient sharedClient] POST:self.testResource.name
                           parameters:newObject
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  response = responseObject;
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  XCTFail(@"Request to create new object should not fail %@", error);
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }];
    
    [self waitForTimeout:1];
    XCTAssert(response, @"There must be a response dictionary");
    for (NSString *key in self.testResource.model.allKeys) {
        if ([key isEqualToString:self.testResource.primaryKey]) {
            XCTAssert([response[key] isEqualToNumber:@1], @"The primary key must be 1");
        } else {
            XCTAssert([response[key] isEqual:newObject[key]], @"The value for %@ in the response and creation dictionaries must be identical %@ %@", key, response[key], newObject[key]);
        }
    }
    
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 1, @"There must be a new object created for the resource");
}

- (void)testCreateObjectWithNoParameters
{
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] POST:self.testResource.name
                           parameters:nil
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  XCTFail(@"Request to create new object with no parameters should not succeed");
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }];
    
    [self waitForTimeout:1];
    XCTAssert(statusCode == 400, @"Status code should indicate a bad request");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 0, @"There must be no resources");
}

- (void)testCreateObjectWithNoMatchingParameters
{
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] POST:self.testResource.name
                           parameters:@{@"foo": @"bar"}
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  XCTFail(@"Request to create new object with no valid parameters should not succeed");
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }];
    
    [self waitForTimeout:1];
    XCTAssert(statusCode == 400, @"Status code should indicate a bad request");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 0, @"There must be no resources");
}

- (void)testUpdateObject
{
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:self.testResource];
    NSString *newObjectKey = newObject.allKeys[0];
    NSString *newObjectValue = newObject[newObjectKey];
    
    [[TGRESTClient sharedClient] POST:self.testResource.name
                           parameters:newObject
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  response = responseObject;
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  XCTFail(@"Request to create new object should not fail %@", error);
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }];
    
    [self waitForTimeout:1];
    XCTAssert(response, @"There must be a response dictionary");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 1, @"There must be a new object created for the resource");
    
    NSString *changedValue = [GZNames name];
    
    __block NSDictionary *changedResponse;
    
    [[TGRESTClient sharedClient] PUT:[NSString stringWithFormat:@"%@/%@", self.testResource.name, response[self.testResource.primaryKey]]
                          parameters:@{newObjectKey: changedValue}
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 changedResponse = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The request to change the object should not fail %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert([changedResponse[newObjectKey] isEqualToString:changedValue], @"The response value should be equal to the new value");
    XCTAssert(![changedResponse[newObjectKey] isEqualToString:newObjectValue], @"The response value should not be equal to the original value");
}

- (void)testUpdateDeletedObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                             parameters:nil
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    response = responseObject;
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    XCTFail(@"The delete request must not have failed %@", error);
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }];
    
    [self waitForTimeout:1];
    
    XCTAssert(statusCode == 204, @"Status code for a delete should be no content");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 9, @"There must be 9 resources after the delete process");
    
    __block NSUInteger updateDeletedStatusCode;
    
    [[TGRESTClient sharedClient] PUT:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                          parameters:@{@"name": [GZNames name]}
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 XCTFail(@"Updating the already deleted object should not be successful");
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 updateDeletedStatusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }];
    
    [self waitForTimeout:1];
    XCTAssert(updateDeletedStatusCode == 410, @"The status code for the response to update a deleted object must be 410 gone");
}

- (void)testUpdateObjectWithNoParameters
{
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:self.testResource];
    
    [[TGRESTClient sharedClient] POST:self.testResource.name
                           parameters:newObject
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  response = responseObject;
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  XCTFail(@"Request to create new object should not fail %@", error);
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }];
    
    [self waitForTimeout:1];
    XCTAssert(response, @"There must be a response dictionary");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 1, @"There must be a new object created for the resource");

    __block NSUInteger changeStatusCode;
    
    [[TGRESTClient sharedClient] PUT:[NSString stringWithFormat:@"%@/%@", self.testResource.name, response[self.testResource.primaryKey]]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 XCTFail(@"Should not receive a successful response when updating an object with a key that does not exist");
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 changeStatusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(changeStatusCode == 400, @"The status code for the request should be of a 400 bad request type");
}

- (void)testUpdateObjectWithNoMatchingParameters
{
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:self.testResource];
    
    [[TGRESTClient sharedClient] POST:self.testResource.name
                           parameters:newObject
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  response = responseObject;
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  XCTFail(@"Request to create new object should not fail %@", error);
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }];
    
    [self waitForTimeout:1];
    XCTAssert(response, @"There must be a response dictionary");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 1, @"There must be a new object created for the resource");
    
    __block NSUInteger changeStatusCode;
    
    [[TGRESTClient sharedClient] PUT:[NSString stringWithFormat:@"%@/%@", self.testResource.name, response[self.testResource.primaryKey]]
                          parameters:@{@"foo": @"bar"}
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 XCTFail(@"Should not receive a successful response when updating an object with a key that does not exist");
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 changeStatusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(changeStatusCode == 400, @"The status code for the request should be of a 400 bad request type");
}

- (void)testUpdateNonexistantObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] PUT:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @15]
                          parameters:@{@"name": [GZNames name]}
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    XCTFail(@"The update request must fail for a non-existant object");
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }];
    
    [self waitForTimeout:1];
    
    XCTAssert(statusCode == 404, @"Status code for an update for a non-existant object should be 404 not found");
}

- (void)testDeleteObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                             parameters:nil
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    response = responseObject;
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    XCTFail(@"The delete request must not have failed %@", error);
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }];
    
    [self waitForTimeout:1];
    
    XCTAssert(statusCode == 204, @"Status code for a delete should be no content");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 9, @"There must be 9 resources after the delete process");
}

- (void)testDeleteAlreadyDeletedObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                             parameters:nil
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    response = responseObject;
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    XCTFail(@"The delete request must not have failed %@", error);
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }];
    
    [self waitForTimeout:1];
    
    XCTAssert(statusCode == 204, @"Status code for a delete should be no content");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 9, @"There must be 9 resources after the delete process");
    
    __block NSUInteger secondDeleteStatusCode;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @5]
                             parameters:nil
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    XCTFail(@"The delete request must not be a success");
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    secondDeleteStatusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }];
    
    [self waitForTimeout:1];
    XCTAssert(secondDeleteStatusCode == 410, @"Status code for an already deleted resource should be 410 Gone");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 9, @"The number of resources must not have changed as a result of the second delete operation");

}

- (void)testDeleteNonexistantObject
{
    [TGTestFactory createTestDataForResource:self.testResource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", self.testResource.name, @15]
                             parameters:nil
                                success:^(NSURLSessionDataTask *task, id responseObject) {
                                    XCTFail(@"The delete request must fail for a non-existant object");
                                    [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                                }
                                failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    statusCode = [[task.response valueForKey:@"statusCode"] integerValue];
                                    [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                }];
    
    [self waitForTimeout:1];
    
    XCTAssert(statusCode == 404, @"Status code for a delete for a non-existant object should be 404 not found");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:self.testResource] == 10, @"The delete process should not have changed the resource count");
}

@end
