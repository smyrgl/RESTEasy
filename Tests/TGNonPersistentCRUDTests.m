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

@interface TGNonPersistentCRUDTests : XCTestCase

@end

@implementation TGNonPersistentCRUDTests

- (void)setUp
{
    [super setUp];
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
}

- (void)tearDown
{
    [[TGRESTServer sharedServer] stopServer];
    [super tearDown];
}

- (void)testGetAllObjectsWithNothing
{
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    __weak typeof(self) weakSelf = self;
    __block NSArray *response;
    
    [[TGRESTClient sharedClient] GET:resource.name
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
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:100];
    
    __weak typeof(self) weakSelf = self;
    __block NSArray *response;
    
    [[TGRESTClient sharedClient] GET:resource.name
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
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:10];
    
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"%@/%@", resource.name, @1]
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
    XCTAssert([response[resource.primaryKey] isEqualToNumber:@1], @"The primary key must equal 1");
}

- (void)testGetNonexistantObject
{
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:10];
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"%@/%@", resource.name, @15]
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
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", resource.name, @5]
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
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 9, @"There must be 9 resources after the delete process");
    
    __block NSUInteger getDeletedStatusCode;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"%@/%@", resource.name, @5]
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

/*

- (void)testCreateObject
{
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 0, @"There must be no resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSDictionary *response;
    
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:resource];
    
    [[TGRESTClient sharedClient] POST:resource.name
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
    for (NSString *key in resource.model.allKeys) {
        if ([key isEqualToString:resource.primaryKey]) {
            XCTAssert([response[key] isEqualToNumber:@1], @"The primary key must be 1");
        } else {
            XCTAssert([response[key] isEqualTo:newObject[key]], @"The value for %@ in the response and creation dictionaries must be identical %@ %@", key, response[key], newObject[key]);
        }
    }
    
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 1, @"There must be a new object created for the resource");
}
 
 */

- (void)testCreateObjectWithNoParameters
{
    
}

- (void)testCreateObjectWithNoMatchingParameters
{
    
}

- (void)testUpdateObject
{
    
}

- (void)testUpdateDeletedObject
{
    
}

- (void)testUpdateObjectWithNoParameters
{
    
}

- (void)testUpdateObjectWithNoMatchingParameters
{
    
}

- (void)testUpdateNonexistantObject
{
    
}

- (void)testDeleteObject
{
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", resource.name, @5]
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
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 9, @"There must be 9 resources after the delete process");
}

- (void)testDeleteAlreadyDeletedObject
{
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    __block id response;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", resource.name, @5]
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
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 9, @"There must be 9 resources after the delete process");
    
    __block NSUInteger secondDeleteStatusCode;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", resource.name, @5]
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
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 9, @"The number of resources must not have changed as a result of the second delete operation");

}

- (void)testDeleteNonexistantObject
{
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:resource], @"The resource must have been successfully added to the server");
    
    [TGTestFactory createTestDataForResource:resource count:10];
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 10, @"There must be 10 resources");
    
    __weak typeof(self) weakSelf = self;
    __block NSUInteger statusCode;
    
    [[TGRESTClient sharedClient] DELETE:[NSString stringWithFormat:@"%@/%@", resource.name, @15]
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
    XCTAssert([[TGRESTServer sharedServer] numberOfObjectsForResource:resource] == 10, @"The delete process should not have changed the resource count");
}

@end
