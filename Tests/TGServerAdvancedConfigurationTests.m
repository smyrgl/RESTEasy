//
//  TGServerAdvancedConfigurationTests.m
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import <XCTest/XCTest.h>
#import "TGTestFactory.h"

@interface TGServerAdvancedConfigurationTests : XCTestCase

@property (nonatomic, strong) TGRESTResource *testResource;

@end

@implementation TGServerAdvancedConfigurationTests

- (void)setUp
{
    [super setUp];
    self.testResource = [TGTestFactory testResource];
}

- (void)tearDown
{
    [[TGRESTServer sharedServer] removeAllResourcesWithData:YES];
    [[TGRESTServer sharedServer] stopServer];
    [super tearDown];
}

- (void)testSetLatency
{
    [[TGRESTServer sharedServer] addResource:self.testResource];
    
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:self.testResource], @"The resource must be successfully added to the server");
    
    [[TGRESTServer sharedServer] startServerWithOptions:@{TGLatencyRangeMinimumOptionKey: @1.0, TGLatencyRangeMaximumOptionKey: @2.0}];
    
    CGFloat latencyMin = [[[TGRESTServer sharedServer] valueForKey:@"latencyMin"] doubleValue];
    CGFloat latencyMax = [[[TGRESTServer sharedServer] valueForKey:@"latencyMax"] doubleValue];
    
    XCTAssert(latencyMin == 1.0f, @"The latency min must have been set successfully");
    XCTAssert(latencyMax == 2.0f, @"The latency min must have been set successfully");
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:self.testResource], @"The added resource must be still be on the server");
}

- (void)testMinimumLatency
{
    [[TGRESTServer sharedServer] addResource:self.testResource];
    
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:self.testResource], @"The resource must be successfully added to the server");
    
    [[TGRESTServer sharedServer] startServerWithOptions:@{TGLatencyRangeMinimumOptionKey: @0.2, TGLatencyRangeMaximumOptionKey: @0.3}];
    NSURL *serverURL = [[TGRESTServer sharedServer] serverURL];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", serverURL, self.testResource.name]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    CGFloat time = TGTimedTestBlock(^{
        NSError *error;
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
        XCTAssertNil(error, @"There must not be an error");
    });
    
    XCTAssert(time > 0.2, @"The response must have taken at least 0.2 seconds");;
}

- (void)testMaximumLatency
{
    [[TGRESTServer sharedServer] addResource:self.testResource];
    
    XCTAssert([[[TGRESTServer sharedServer] currentResources] containsObject:self.testResource], @"The resource must be successfully added to the server");
    
    [[TGRESTServer sharedServer] startServerWithOptions:@{TGLatencyRangeMinimumOptionKey: @0.2, TGLatencyRangeMaximumOptionKey: @0.5}];
    NSURL *serverURL = [[TGRESTServer sharedServer] serverURL];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", serverURL, self.testResource.name]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    CGFloat time = TGTimedTestBlock(^{
        NSError *error;
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
        XCTAssertNil(error, @"There must not be an error");
    });
    
    XCTAssert(time < 0.55, @"The response must have taken less than 0.55 seconds");
    XCTAssert(time > 0.2, @"The response must have taken more than 0.2 seconds");
}

@end
