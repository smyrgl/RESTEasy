//
//  TGSqliteStoreTests.m
//  Tests
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import <XCTest/XCTest.h>
#import "TGRESTSqliteStore.h"
#import "TGTestFactory.h"

@interface TGSqliteStoreTests : XCTestCase

@property (nonatomic, strong) TGRESTResource *testNormalResource;
@property (nonatomic, strong) TGRESTResource *testParentResource;
@property (nonatomic, strong) TGRESTResource *testChildResource;

@property (nonatomic, strong) TGRESTSqliteStore *store;

@end

@implementation TGSqliteStoreTests

- (void)setUp
{
    [super setUp];
    
    self.store = [TGRESTSqliteStore new];
    self.testNormalResource = [TGTestFactory testResource];
    self.testParentResource = [TGTestFactory testResource];
    self.testChildResource = [TGTestFactory testResourceWithParent:self.testParentResource];
    
    [self.store addResource:self.testNormalResource];
    [self.store addResource:self.testParentResource];
    [self.store addResource:self.testChildResource];
}

- (void)tearDown
{
    [self.store dropResource:self.testNormalResource];
    [self.store dropResource:self.testParentResource];
    [self.store dropResource:self.testChildResource];
    
    [super tearDown];
}

- (void)testCountOfObjectsForResource
{
    NSUInteger count = [self.store countOfObjectsForResource:self.testNormalResource];
    XCTAssert(count == 0, @"There should be no objects");
    
    NSArray *newObjects = [TGTestFactory buildTestDataForResource:self.testNormalResource count:10];
    for (NSDictionary *newResourceDict in newObjects) {
        NSError *createError;
        [self.store createNewObjectForResource:self.testNormalResource withProperties:newResourceDict error:&createError];
        XCTAssert(!createError, @"There should not be an error");
        count++;
    }
    
    XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == count, @"The number of objects must equal the incremented expected count.");
}

- (void)testCreateResource
{
    NSUInteger count = [self.store countOfObjectsForResource:self.testNormalResource];
    XCTAssert(count == 0, @"There should be no objects");
    
    NSDictionary *properties = [TGTestFactory buildTestDataForResource:self.testNormalResource];
    NSError *error;
    [self.store createNewObjectForResource:self.testNormalResource
                            withProperties:properties
                                     error:&error];
    
    XCTAssert(!error, @"There should not be an error");
    XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == 1, @"There should be 1 object");
}

- (void)testGetResource
{
    NSMutableSet *createdObjects = [NSMutableSet new];
    NSArray *newObjects = [TGTestFactory buildTestDataForResource:self.testNormalResource count:10];
    for (NSDictionary *newResourceDict in newObjects) {
        NSError *error;
        NSDictionary *newObjectDict = [self.store createNewObjectForResource:self.testNormalResource withProperties:newResourceDict error:&error];
        XCTAssert(!error, @"There should not be an error");
        if (newObjectDict) {
            [createdObjects addObject:newObjectDict];
        } else {
            XCTFail(@"Creating a new object must return a dictionary");
        }
    }
    
    XCTAssert(createdObjects.count == 10, @"There should be 10 objects");
    NSDictionary *randomObject = [createdObjects anyObject];
    XCTAssert(randomObject[self.testNormalResource.primaryKey], @"The object dictionary must have a primary key.");
    
    NSError *fetchError;
    NSDictionary *copyRandomObject = [self.store getDataForObjectOfResource:self.testNormalResource withPrimaryKey:randomObject[self.testNormalResource.primaryKey] error:&fetchError];
    
    XCTAssert(!fetchError, @"There must not be a fetch error");
    XCTAssert([copyRandomObject isEqualToDictionary:randomObject], @"The returned dictionary should be equal to the one that was returned during the creation process.");
}

@end
