//
//  TGBasicServerTests.m
//  Tests
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <XCTest/XCTest.h>
#import "TGTestFactory.h"
#import "TGRESTClient.h"

@interface TGBasicServerTests : XCTestCase

@end

@implementation TGBasicServerTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [[TGRESTServer sharedServer] removeAllResourcesWithData:YES];
    [[TGRESTServer sharedServer] stopServer];
    [super tearDown];
}

#pragma mark - Normal testing

- (void)testStartServer
{
    XCTAssert(![[TGRESTServer sharedServer] isRunning], @"Server must not be running");
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
    XCTAssert([[TGRESTServer sharedServer] isRunning], @"Server must be running");
}

- (void)testStopServer
{
    XCTAssert(![[TGRESTServer sharedServer] isRunning], @"Server must not be running");
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
    XCTAssert([[TGRESTServer sharedServer] isRunning], @"Server must be running");
    [[TGRESTServer sharedServer] stopServer];
    XCTAssert(![[TGRESTServer sharedServer] isRunning], @"Server must not be running");
}

- (void)testAddResource
{
    XCTAssert([[TGRESTServer sharedServer] currentResources].count == 0, @"There should be zero current resources");
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    NSSet *resources = [[TGRESTServer sharedServer] currentResources];
    XCTAssert(resources.count == 1, @"There should be one resource");
    TGRESTResource *newResource = [resources anyObject];
    XCTAssert(newResource == resource, @"The new resource should be the same as the created resource");
}

- (void)testAddData
{
    XCTAssert([[TGRESTServer sharedServer] currentResources].count == 0, @"There should be zero current resources");
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:resource];
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
    [TGTestFactory createTestDataForResource:resource count:100];
    
    __block NSArray *response;
    __weak typeof(self) weakSelf = self;
    
    [[TGRESTClient sharedClient] GET:resource.name
                          parameters:nil
                             success:^(NSURLSessionDataTask *task, id responseObject) {
                                 response = responseObject;
                                 [weakSelf notify:XCTAsyncTestCaseStatusSucceeded];
                             }
                             failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 XCTFail(@"The request must not have failed, %@", error);
                             }];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:2];
    
    XCTAssert(response.count == 100, @"There must be 100 objects in the response");
}

#pragma mark - Negative testing

- (void)testAddSameNameResource
{
    XCTAssert([[TGRESTServer sharedServer] currentResources].count == 0, @"There should be zero current resources");
    TGRESTResource *oldResource = [TGTestFactory testResource];
    [[TGRESTServer sharedServer] addResource:oldResource];
    XCTAssert([[TGRESTServer sharedServer] currentResources].count == 1, @"There should be one resource");
    XCTAssert([[[TGRESTServer sharedServer] currentResources] anyObject] == oldResource, @"The old resource should be the same as the returned resource");
    
    NSDictionary *model = @{@"newprop": [NSNumber numberWithInteger:TGPropertyTypeString]};
    TGRESTResource *newResource = [TGRESTResource newResourceWithName:oldResource.name model:model];
    [[TGRESTServer sharedServer] addResource:newResource];
    XCTAssert([[TGRESTServer sharedServer] currentResources].count == 1, @"There should be one resource");
    XCTAssert([[[TGRESTServer sharedServer] currentResources] anyObject] == newResource, @"The new resource should be the same as the returned resource");

}

@end
