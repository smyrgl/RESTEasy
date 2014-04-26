//
//  TGPersistenceTests.m
//  Tests
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import <XCTest/XCTest.h>
#import "TGTestFactory.h"

@interface TGPersistenceTests : XCTestCase

@end

@implementation TGPersistenceTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testResetStore
{
    [[TGRESTPersistentServer sharedServer] startServerWithOptions:nil];
    TGRESTResource *resource = [TGTestFactory testResource];
    [[TGRESTPersistentServer sharedServer] addResource:resource];
    [TGTestFactory createTestDataForResource:resource count:10];
    [[TGRESTPersistentServer sharedServer] removeAllResourcesWithData:YES];
    
   // XCTAssert([[TGRESTPersistentServer sharedServer] currentResources].count == 0, @"There should be zero resources");
   // XCTAssert([[TGRESTPersistentServer sharedServer] numberOfObjectsForResource:resource] == 0, @"There should be zero objects for the resource");
}

@end
