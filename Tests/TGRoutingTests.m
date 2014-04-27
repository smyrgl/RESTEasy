//
//  TGRelationalRoutingTests.m
//  Tests
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import <XCTest/XCTest.h>
#import "TGRESTClient.h"
#import "TGTestFactory.h"
#import <Gizou/Gizou.h>

@interface TGRoutingTests : XCTestCase

@property (nonatomic, strong) TGRESTResource *childResource;
@property (nonatomic, strong) TGRESTResource *parentResource;

@property (nonatomic, copy) NSDictionary *testChildObjectDict;
@property (nonatomic, copy) NSDictionary *testParentObjectDict;
@property (nonatomic, copy) NSDictionary *testSecondaryParentObjectDict;
@property (nonatomic, copy) NSArray *testSecondaryChildrenObjectDicts;

@end

@implementation TGRoutingTests

- (void)setUp
{
    [super setUp];
    NSDictionary *parentModel = @{
                                  @"name": [NSNumber numberWithInteger:TGPropertyTypeString]
                                  };
    NSDictionary *childModel = @{
                                 @"address": [NSNumber numberWithInteger:TGPropertyTypeString]
                                 };
    
    self.parentResource = [TGRESTResource newResourceWithName:@"people" model:parentModel];
    self.childResource = [TGRESTResource newResourceWithName:@"email" model:childModel actions:TGResourceRESTActionsPOST | TGResourceRESTActionsPUT | TGResourceRESTActionsGET | TGResourceRESTActionsDELETE primaryKey:nil parentResources:@[self.parentResource]];
    
    [[TGRESTServer sharedServer] addResourcesWithArray:@[self.parentResource, self.childResource]];
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:TGRESTServerDidStartNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                                                  }];
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
    [self waitForTimeout:2];
    
    NSDictionary *parentData = @{@"name": [GZNames name]};
    
    [[TGRESTServer sharedServer] addData:@[parentData] forResource:self.parentResource];
    
    self.testParentObjectDict = [[TGRESTServer sharedServer] allObjectsForResource:self.parentResource][0];
    NSParameterAssert(self.testParentObjectDict);
    
    NSDictionary *childData = @{@"address": [GZInternet email], self.childResource.foreignKeys[self.parentResource.name]: self.testParentObjectDict[self.parentResource.primaryKey]};
    
    [[TGRESTServer sharedServer] addData:@[childData] forResource:self.childResource];
    
    self.testChildObjectDict = [[TGRESTServer sharedServer] allObjectsForResource:self.childResource][0];
    NSParameterAssert(self.testChildObjectDict);
    
    parentData = @{@"name": [GZNames name]};
    [[TGRESTServer sharedServer] addData:@[parentData] forResource:self.parentResource];
    NSArray *allParents = [[TGRESTServer sharedServer] allObjectsForResource:self.parentResource];
    
    for (NSDictionary *dict in allParents) {
        if ([dict[@"name"] isEqualToString:parentData[@"name"]]) {
            self.testSecondaryParentObjectDict = dict;
        }
    }
    
    NSMutableArray *newChildren = [NSMutableArray new];
    
    for (int x = 0; x < 5; x++) {
        NSDictionary *newChildData = @{@"address": [GZInternet email], self.childResource.foreignKeys[self.parentResource.name]: self.testSecondaryParentObjectDict[self.parentResource.primaryKey]};
        [newChildren addObject:newChildData];
    }
    
    [[TGRESTServer sharedServer] addData:newChildren forResource:self.childResource];
    
    NSMutableArray *secondaryChildren = [NSMutableArray new];
    NSArray *allChildren = [[TGRESTServer sharedServer] allObjectsForResource:self.childResource];
    
    for (NSDictionary *childDict in allChildren) {
        if ([childDict[self.childResource.foreignKeys[self.parentResource.name]] isEqualTo:self.testSecondaryParentObjectDict[self.parentResource.primaryKey]]) {
            [secondaryChildren addObject:childDict];
        }
    }
    
    self.testSecondaryChildrenObjectDicts = [NSArray arrayWithArray:secondaryChildren];
}

- (void)tearDown
{
    [[TGRESTServer sharedServer] removeAllResourcesWithData:YES];
    [[TGRESTServer sharedServer] stopServer];
    [super tearDown];
}

#pragma mark - Normal routing tests

- (void)testBaseIndexRoute
{
    __block NSArray *response;
    __weak typeof(self) weakSelf = self;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"/%@", self.parentResource.name]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The parent base index request must not be a failure %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(response.count == 2, @"There should be one object in the response array");
    XCTAssert([response[0] isEqualToDictionary:self.testParentObjectDict], @"The object returned should be identical to the test parent object");
}

- (void)testBaseChildIndexRoute
{
    __block NSArray *response;
    __weak typeof(self) weakSelf = self;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"/%@", self.childResource.name]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The child base index request must not be a failure %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(response.count == 6, @"There should be one object in the response array");
    XCTAssert([response[0] isEqualToDictionary:self.testChildObjectDict], @"The object returned should be identical to the test child object");
}

- (void)testNestedSingularIndexRoute
{
    __block NSArray *response;
    __weak typeof(self) weakSelf = self;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"/%@/%@/%@", self.parentResource.name, self.testParentObjectDict[self.parentResource.primaryKey], self.childResource.name]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The child nested index request must not be a failure %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(response.count == 1, @"There should be one object in the response array");
    XCTAssert([response[0] isEqualToDictionary:self.testChildObjectDict], @"The object returned should be identical to the test child object");
}

- (void)testNestedMultipleIndexRoute
{
    __block NSArray *response;
    __weak typeof(self) weakSelf = self;
    
    [[TGRESTClient sharedClient] GET:[NSString stringWithFormat:@"/%@/%@/%@", self.parentResource.name, self.testSecondaryParentObjectDict[self.parentResource.primaryKey], self.childResource.name]
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The child nested index request must not be a failure %@", error);
                                 [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                             }];
    
    [self waitForTimeout:1];
    
    XCTAssert(response.count == self.testSecondaryChildrenObjectDicts.count, @"There should be one object in the response array");
    XCTAssert([response isEqualToArray:self.testSecondaryChildrenObjectDicts], @"The response should be the same as the array of secondary test children");
}

- (void)testBaseCreateRoute
{
    __block NSDictionary *response;
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *params = @{@"name": [GZNames name]};
    
    [[TGRESTClient sharedClient] POST:[NSString stringWithFormat:@"/%@", self.parentResource.name]
                           parameters:params
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  response = responseObject;
                                  [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  XCTFail(@"The request to the base create route must not fail %@", error);
                                  [weakSelf notify:XCTAsyncTestCaseStatusFailed];
                              }];
    
    [self waitForTimeout:1];
    
    XCTAssert([response[@"name"] isEqualToString:params[@"name"]], @"The returned object must include a name with the value in the passed param");
    XCTAssert([response[self.parentResource.primaryKey] isEqualTo:[NSNumber numberWithInteger:3]], @"Must include a primary key which should be set at 3 since there are 2 existing parent resources");
}

/*

- (void)testNestedCreateRoute
{
    
}

- (void)testBaseShowRoute
{
    
}

- (void)testBaseUpdateRoute
{
    
}


- (void)testBaseDeleteRoute
{
    
}


#pragma mark - Negative tests

- (void)testNestedShowRoute
{
    
}

- (void)testNestedUpdateRoute
{
    
}

- (void)testNestedDeleteRoute
{
    
}

- (void)testNestedIndexRouteParentKeyNonexistant
{
    
}

- (void)testNestedIndexRouteDeletedParent
{
    
}

- (void)testNestedIndexRouteNotParentResource
{
    
}

- (void)testDeepNesting
{
    
}
 
 */

@end
