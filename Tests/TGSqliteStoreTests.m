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

static dispatch_group_t sqlite_store_test_group() {
    static dispatch_group_t sqlite_store_test_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sqlite_store_test_group = dispatch_group_create();
    });
    
    return sqlite_store_test_group;
}

static dispatch_queue_t sqlite_store_test_queue() {
    static dispatch_queue_t sqlite_store_test_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sqlite_store_test_queue = dispatch_queue_create("com.tinylittlegears.resteasy.sqlite.test", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return sqlite_store_test_queue;
}


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
        XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == count, @"The number of objects must equal the incremented expected count.");
    }
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

- (void)testGetAllObjectsForResource
{
    XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == 0, @"There should be no objects");
    
    NSArray *newObjects = [TGTestFactory buildTestDataForResource:self.testNormalResource count:10];
    
    NSMutableArray *mergeArray = [NSMutableArray new];
    
    for (NSDictionary *newResourceDict in newObjects) {
        NSError *createError;
        NSMutableDictionary *mergeDict = [NSMutableDictionary dictionaryWithDictionary:newResourceDict];
        NSDictionary *newObj = [self.store createNewObjectForResource:self.testNormalResource withProperties:newResourceDict error:&createError];
        [mergeDict addEntriesFromDictionary:newObj];
        [mergeArray addObject:mergeDict];
        XCTAssert(!createError, @"There should not be an error");
    }
    
    NSError *fetchError;
    XCTAssert([mergeArray isEqualToArray:[self.store getAllObjectsForResource:self.testNormalResource error:&fetchError]], @"The fetch for all objects must be the same as the expected array");
    XCTAssert(!fetchError, @"There must not be an error");
}

- (void)testGetAllChildObjectsForParent
{
    NSDictionary *parentAttributes = [TGTestFactory buildTestDataForResource:self.testParentResource];
    NSArray *childAttributes = [TGTestFactory buildTestDataForResource:self.testChildResource count:5];
    
    NSError *parentCreateError;
    NSDictionary *parentObject = [self.store createNewObjectForResource:self.testParentResource withProperties:parentAttributes error:&parentCreateError];
    XCTAssertNil(parentCreateError, @"There must not be an error creating the parent resource %@", parentCreateError);
    
    NSMutableArray *childArray = [NSMutableArray new];
    
    for (NSDictionary *childPropertiesDict in childAttributes) {
        NSMutableDictionary *childProperties = [NSMutableDictionary dictionaryWithDictionary:childPropertiesDict];
        [childProperties setObject:parentObject[self.testParentResource.primaryKey] forKey:self.testChildResource.foreignKeys[self.testParentResource.name]];
        NSError *createChildError;
        NSDictionary *childObject = [self.store createNewObjectForResource:self.testChildResource withProperties:childProperties error:&createChildError];
        XCTAssertNil(createChildError, @"There must not be an error creating a child object %@", createChildError);
        [childArray addObject:childObject];
    }
    
    NSError *fetchError;
    NSArray *fetchChildren = [self.store getDataForObjectsOfResource:self.testChildResource withParent:self.testParentResource parentPrimaryKey:parentObject[self.testParentResource.primaryKey] error:&fetchError];
    
    XCTAssertNil(fetchError, @"There must not be an error fetch child objects for a parent %@", fetchError);
    XCTAssert([fetchChildren isEqualToArray:childArray], @"The returned array must be identical to the array of children that were created.");
}

- (void)testModifyObject
{
    NSDictionary *properties = [TGTestFactory buildTestDataForResource:self.testNormalResource];
    NSError *error;
    
    NSDictionary *newObject = [self.store createNewObjectForResource:self.testNormalResource
                                                      withProperties:properties
                                                               error:&error];
    
    XCTAssert(!error, @"There must not be an error creating a new object %@", error);
    
    NSDictionary *newProperties = [TGTestFactory buildTestDataForResource:self.testNormalResource];
    NSError *modifyError;
    NSDictionary *updatedObject = [self.store modifyObjectOfResource:self.testNormalResource withPrimaryKey:newObject[self.testNormalResource.primaryKey] withProperties:newProperties error:&modifyError];
    
    XCTAssertNil(modifyError, @"There must not be an error modifying an existing resource %@", modifyError);
    XCTAssert([updatedObject[self.testNormalResource.primaryKey] isEqual:newObject[self.testNormalResource.primaryKey]], @"The primary key must be the same on both objects");
    
    NSMutableDictionary *updatedObjectMinusKey = [updatedObject mutableCopy];
    [updatedObjectMinusKey removeObjectForKey:self.testNormalResource.primaryKey];
    
    XCTAssert([updatedObjectMinusKey isEqualToDictionary:newProperties], @"The updated object minus the primary key must be equal to the properties provided");
}

- (void)testDeleteObject
{
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:self.testNormalResource];
    NSError *createError;
    NSDictionary *createdNewObject = [self.store createNewObjectForResource:self.testNormalResource withProperties:newObject error:&createError];
    XCTAssert(!createError, @"There must not be an error creating the error");
    
    NSError *deleteError;
    XCTAssertNoThrow([self.store deleteObjectOfResource:self.testNormalResource withPrimaryKey:createdNewObject[self.testNormalResource.primaryKey] error:&deleteError], @"Deleting should not throw an error.");
    
    XCTAssert(!deleteError, @"There must not be an error deleting the resource");
    XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == 0, @"The count must have been zero");
}

- (void)testDeleteObjectCount
{
    NSUInteger count = [self.store countOfObjectsForResource:self.testNormalResource];
    XCTAssert(count == 0, @"There must be no objects");
    
    NSArray *newObjects = [TGTestFactory buildTestDataForResource:self.testNormalResource count:10];
    NSMutableSet *createdObjects = [NSMutableSet new];
    for (NSDictionary *newResourceDict in newObjects) {
        NSError *createError;
        NSDictionary *createdNewObject = [self.store createNewObjectForResource:self.testNormalResource withProperties:newResourceDict error:&createError];
        [createdObjects addObject:createdNewObject];
        XCTAssert(!createError, @"There must not be an error creating the error");
        count++;
    }
    
    XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == count, @"The reported resource count must equal the number of objects created.");
    
    NSError *deleteError;
    [self.store deleteObjectOfResource:self.testNormalResource withPrimaryKey:[createdObjects anyObject][self.testNormalResource.primaryKey] error:&deleteError];
    
    XCTAssert(!deleteError, @"There must not be an error deleting the resource");
    XCTAssert([self.store countOfObjectsForResource:self.testNormalResource] == count - 1, @"The count must have been decremented by one");
}

- (void)testGetDeletedObject
{
    NSDictionary *newObject = [TGTestFactory buildTestDataForResource:self.testNormalResource];
    NSError *createError;
    NSDictionary *createdNewObject = [self.store createNewObjectForResource:self.testNormalResource withProperties:newObject error:&createError];
    XCTAssert(!createError, @"There must not be an error creating the error");
    
    NSError *deleteError;
    [self.store deleteObjectOfResource:self.testNormalResource withPrimaryKey:createdNewObject[self.testNormalResource.primaryKey] error:&deleteError];
    XCTAssert(!deleteError, @"There must not be an error deleting the resource");
    
    NSError *fetchError;
    NSDictionary *deletedObject = [self.store getDataForObjectOfResource:self.testNormalResource withPrimaryKey:createdNewObject[self.testNormalResource.primaryKey] error:&fetchError];
    
    XCTAssert(fetchError, @"The must be a fetch error returned");
    XCTAssert(fetchError.code == TGRESTStoreObjectAlreadyDeletedErrorCode, @"The error must be of an already deleted error code");
    XCTAssertNil(deletedObject, @"The return dictionary must be nil");
}

- (void)testAddResource
{
    TGRESTResource *newResource = [TGTestFactory testResource];
    [self.store addResource:newResource];
    NSDictionary *buildObjectDict = [TGTestFactory buildTestDataForResource:newResource];
    
    NSDictionary *createdObjectDict;
    
    NSError *error;
    XCTAssertNoThrow(createdObjectDict = [self.store createNewObjectForResource:newResource withProperties:buildObjectDict error:&error], @"Creating an object for the new resource must not throw an exception");
    
    XCTAssertNil(error, @"There must not be an error %@", error);
    XCTAssert(createdObjectDict, @"There must be an object returned");
}

- (void)testRemoveResource
{
    TGRESTResource *newResource = [TGTestFactory testResource];
    [self.store addResource:newResource];
    NSDictionary *buildObjectDict = [TGTestFactory buildTestDataForResource:newResource];
    
    NSDictionary *createdObjectDict = [self.store createNewObjectForResource:newResource withProperties:buildObjectDict error:nil];
    XCTAssert(createdObjectDict, @"There must be an object returned");
    
    [self.store dropResource:newResource];
    
    NSError *error;
    NSDictionary *droppedObject = [self.store getDataForObjectOfResource:newResource withPrimaryKey:createdObjectDict[newResource.primaryKey] error:&error];
    
    XCTAssert(error, @"An error must be thrown when trying to access a non-existant object");
    XCTAssertNil(droppedObject, @"There must be no object returned");
}

- (void)testThreadSafety
{
    TGRESTResource *newResource = [TGTestFactory testResource];
    TGRESTStore *store = self.store;
    
    NSArray *newResourceProperties = [TGTestFactory buildTestDataForResource:newResource count:1000];
    for (int x = 0; x < newResourceProperties.count; x++) {
        dispatch_group_async(sqlite_store_test_group(), sqlite_store_test_queue(), ^{
            NSDictionary *objectPropertyDict = newResourceProperties[x];
            NSError *error;
            [store createNewObjectForResource:newResource withProperties:objectPropertyDict error:&error];
            XCTAssertNil(error, @"There must not be an error");
        });
    }
    
    dispatch_group_wait(sqlite_store_test_group(), DISPATCH_TIME_FOREVER);
    
    NSError *fetchError;
    NSArray *currentResources = [store getAllObjectsForResource:newResource error:&fetchError];
    
    XCTAssertNil(fetchError, @"There must not be a fetch error %@", fetchError);
    XCTAssert(currentResources.count == newResourceProperties.count, @"The number of objects in the datastore must match the number of objects created");
}

@end
