//
//  TGRelationalRoutingTests.m
//  Tests
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import <XCTest/XCTest.h>

@interface TGRoutingTests : XCTestCase

@end

@implementation TGRoutingTests

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

#pragma mark - Normal routing tests

- (void)testBaseIndexRoute
{
    
}

- (void)testNestedIndexRoute
{
    
}

- (void)testManyToManyIndexRoute
{
    
}

- (void)testBaseCreateRoute
{
    
}

- (void)testNestedCreateRoute
{
    
}

- (void)testManyToMainCreateRoute
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

@end
