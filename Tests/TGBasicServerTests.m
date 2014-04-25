//
//  TGBasicServerTests.m
//  Tests
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <XCTest/XCTest.h>
#import "RESTEasy.h"

@interface TGBasicServerTests : XCTestCase

@end

@implementation TGBasicServerTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [[TGRESTServer sharedServer] stopServer];
    [super tearDown];
}

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
    [[TGRESTServer sharedServer] startServerWithOptions:nil];
    XCTAssert([[TGRESTServer sharedServer] currentResources].count == 0, @"There should be zero current resources");
    TGRESTResource *resource = [TGRESTResource newResourceWithName:@"person" model:@{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]} routes:nil actions:TGResourceRESTActionsGET primaryKey:nil];
    [[TGRESTServer sharedServer] addResource:resource];
    NSSet *resources = [[TGRESTServer sharedServer] currentResources];
    XCTAssert(resources.count == 1, @"There should be one resource");
    TGRESTResource *newResource = [resources anyObject];
    XCTAssert(newResource == resource, @"The new resource should be the same as the created resource");
}

- (void)testAddPersistentResource
{
    [[TGRESTServer sharedServer] startServerWithOptions:@{TGPersistenceNameOptionKey: @"mine"}];
    TGRESTResource *resource = [TGRESTResource newResourceWithName:@"person" model:@{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]} routes:nil actions:TGResourceRESTActionsGET primaryKey:nil];
    [[TGRESTServer sharedServer] addResource:resource];
    NSSet *resources = [[TGRESTServer sharedServer] currentResources];
    XCTAssert(resources.count == 1, @"There should be one resource");
    TGRESTResource *newResource = [resources anyObject];
    XCTAssert(newResource == resource, @"The new resource should be the same as the created resource");
}

@end
