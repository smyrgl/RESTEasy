//
//  TGBasicModelTests.m
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import <XCTest/XCTest.h>
#import "TGTestFactory.h"

@interface TGResourceTests : XCTestCase

@end

@implementation TGResourceTests

#pragma mark - Setup

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

#pragma mark - Standard tests

- (void)testNameModelConstructor
{
    // Define a basic resource
    
    TGRESTResource *resource;
    NSString *resourceName = @"human";
    NSDictionary *model = @{
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                            @"children": [NSNumber numberWithInteger:TGPropertyTypeInteger]
                            };
    
    // First make sure it doesn't throw an exception during creation
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:resourceName model:model]);
    
    // Now test that the properties are at least valid
    
    XCTAssert(resource.name && resource.name.length > 0, @"There must be a valid name");
    XCTAssert(resource.model && resource.model.allKeys.count > 0, @"There must be a valid model");
    XCTAssert(resource.parentResources && resource.parentResources.count == 0, @"There must be a parent resources array and it should be empty");
    XCTAssert(resource.foreignKeys && resource.foreignKeys.allKeys.count == 0, @"There must be a foreign keys dictionary and it should be empty");
    XCTAssert(resource.primaryKey, @"There must be a primary key ");
    XCTAssert(resource.actions, @"There must be valid actions");
    XCTAssert(resource.primaryKeyType, @"There must be a primary key type");
    
    // Now test that the properties are the expected defaults
    
    XCTAssert([resource.name isEqualToString:resourceName], @"The name of the resource must be what was specified");
    XCTAssert(resource.model.count == 3, @"There should be 3 key/values in the model when you include the primary key");
    XCTAssert(resource.actions == (TGResourceRESTActionsPOST | TGResourceRESTActionsPUT | TGResourceRESTActionsGET | TGResourceRESTActionsDELETE), @"All four default action verbs should be enabled");
    
    // Check that the model is what was passed plus the primary key
    
    NSMutableDictionary *expectedModel = [NSMutableDictionary dictionaryWithDictionary:model];
    [expectedModel setObject:[NSNumber numberWithInteger:TGPropertyTypeInteger] forKey:@"id"];
    XCTAssert([resource.model isEqualToDictionary:expectedModel], @"The model dictionary must match the expected model dictionary");
}

- (void)testNameModelActionsKeyConstructor
{
    // Define a basic resource
    
    TGRESTResource *resource;
    NSString *resourcePKey = @"human_id";
    NSString *resourceName = @"human";
    NSDictionary *model = @{
                            @"human_id": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                            @"children": [NSNumber numberWithInteger:TGPropertyTypeInteger]
                            };
    
    // First make sure it doesn't throw an exception during creation
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:resourceName model:model actions:TGResourceRESTActionsPOST | TGResourceRESTActionsGET primaryKey:resourcePKey]);
    
    // Now test that the properties are at least valid
    
    XCTAssert(resource.name && resource.name.length > 0, @"There must be a valid name");
    XCTAssert(resource.model && resource.model.allKeys.count > 0, @"There must be a valid model");
    XCTAssert(resource.parentResources && resource.parentResources.count == 0, @"There must be a parent resources array and it should be empty");
    XCTAssert(resource.foreignKeys && resource.foreignKeys.allKeys.count == 0, @"There must be a foreign keys dictionary and it should be empty");
    XCTAssert(resource.primaryKey, @"There must be a primary key ");
    XCTAssert(resource.actions, @"There must be valid actions");
    XCTAssert(resource.primaryKeyType, @"There must be a primary key type");
    
    // Now test that the properties are the expected defaults
    
    XCTAssert([resource.name isEqualToString:resourceName], @"The name of the resource must be what was specified");
    XCTAssert([resource.primaryKey isEqualToString:resourcePKey], @"The primary key must equal the primary key specified");
    XCTAssert([resource.model isEqualToDictionary:model] , @"The models must be identical since we specified the primary key explicitly");
    XCTAssert(resource.actions == (TGResourceRESTActionsPOST | TGResourceRESTActionsGET), @"POST and GET should be the actions set");
}

- (void)testNameModelActionsKeyParentsConstructor
{
    // First create a parent resource
    
    TGRESTResource *parentResource = [TGTestFactory randomModelTestResource];
    
    // Now define the child resource
    
    TGRESTResource *resource;
    NSString *resourcePKey = @"human_id";
    NSString *resourceName = @"human";
    NSDictionary *model = @{
                            @"human_id": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                            @"children": [NSNumber numberWithInteger:TGPropertyTypeInteger]
                            };
    NSArray *parents = @[parentResource];
    
    // First make sure it doesn't throw an exception during creation
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:resourceName model:model actions:TGResourceRESTActionsPOST | TGResourceRESTActionsGET primaryKey:resourcePKey parentResources:parents]);
    
    // Now test that the properties are at least valid
    
    XCTAssert(resource.name && resource.name.length > 0, @"There must be a valid name");
    XCTAssert(resource.model && resource.model.allKeys.count > 0, @"There must be a valid model");
    XCTAssert(resource.parentResources, @"There must be a parents resource array");
    XCTAssert(resource.foreignKeys, @"There must be a foreign keys dictionary");
    XCTAssert(resource.primaryKey, @"There must be a primary key ");
    XCTAssert(resource.actions, @"There must be valid actions");
    XCTAssert(resource.primaryKeyType, @"There must be a primary key type");
    
    // Now test that the properties are the expected defaults
    
    NSString *expectedForeignKey = [NSString stringWithFormat:@"%@_id", parentResource.name];
    
    NSMutableDictionary *expectedModel = [NSMutableDictionary dictionaryWithDictionary:model];
    [expectedModel setObject:[NSNumber numberWithInteger:parentResource.primaryKeyType] forKey:expectedForeignKey];
    
    XCTAssert([resource.parentResources isEqualToArray:parents], @"The parents resources array should equal to one we passed");
    XCTAssert([resource.name isEqualToString:resourceName], @"The name of the resource must be what was specified");
    XCTAssert([resource.primaryKey isEqualToString:resourcePKey], @"The primary key must equal the primary key specified");
    XCTAssert([resource.model isEqualToDictionary:expectedModel] , @"The models must match the specified model plus the parent foreign key");
    XCTAssert(resource.actions == (TGResourceRESTActionsPOST | TGResourceRESTActionsGET), @"POST and GET should be the actions set");
    XCTAssert(resource.foreignKeys.count == 1 , @"There should be one foreign key");
    XCTAssert([resource.foreignKeys[parentResource.name] isEqualToString:expectedForeignKey], @"The foreign key dictionary value for the parent name should be the expected foreign key");
}

- (void)testNameModelActionsKeyParentsFkeysConstructor
{
    // First create a parent resource
    
    TGRESTResource *parentResource = [TGTestFactory randomModelTestResource];
    
    // Now define the child resource
    
    TGRESTResource *resource;
    NSString *resourcePKey = @"human_id";
    NSString *customFkey = @"parent_id";
    NSString *resourceName = @"human";
    NSDictionary *model = @{
                            resourcePKey: [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                            @"children": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            customFkey: [NSNumber numberWithInteger:parentResource.primaryKeyType]
                            };
    NSArray *parents = @[parentResource];
    NSDictionary *fKeys = @{parentResource.name: customFkey};
    
    // First make sure it doesn't throw an exception during creation
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:resourceName model:model actions:TGResourceRESTActionsPOST | TGResourceRESTActionsGET primaryKey:resourcePKey parentResources:parents foreignKeys:fKeys]);
    
    // Now test that the properties are at least valid
    
    XCTAssert(resource.name && resource.name.length > 0, @"There must be a valid name");
    XCTAssert(resource.model && resource.model.allKeys.count > 0, @"There must be a valid model");
    XCTAssert(resource.parentResources, @"There must be a parents resource array");
    XCTAssert(resource.foreignKeys, @"There must be a foreign keys dictionary");
    XCTAssert(resource.primaryKey, @"There must be a primary key ");
    XCTAssert(resource.actions, @"There must be valid actions");
    XCTAssert(resource.primaryKeyType, @"There must be a primary key type");
    
    // Now test that the properties are the expected defaults
    
    XCTAssert([resource.parentResources isEqualToArray:parents], @"The parents resources array should equal to one we passed");
    XCTAssert([resource.name isEqualToString:resourceName], @"The name of the resource must be what was specified");
    XCTAssert([resource.primaryKey isEqualToString:resourcePKey], @"The primary key must equal the primary key specified");
    XCTAssert([resource.model isEqualToDictionary:model] , @"The models must match the provided model exactly since we explictly set the foreign key");
    XCTAssert(resource.actions == (TGResourceRESTActionsPOST | TGResourceRESTActionsGET), @"POST and GET should be the actions set");
    XCTAssert(resource.foreignKeys.count == 1 , @"There should be one foreign key");
    XCTAssert([resource.foreignKeys[parentResource.name] isEqualToString:customFkey], @"The foreign key dictionary value for the parent name should be the custom foreign key");
}

- (void)testModelPropertyTypes
{
    NSDictionary *model = @{
                            @"string": [NSNumber numberWithInteger:TGPropertyTypeString],
                            @"integer": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            @"float": [NSNumber numberWithInteger:TGPropertyTypeFloatingPoint],
                            @"blob": [NSNumber numberWithInteger:TGPropertyTypeBlob]
                            };
    
    TGRESTResource *resource = [TGRESTResource newResourceWithName:@"test" model:model];
    
    NSMutableDictionary *expectedModel = [NSMutableDictionary dictionaryWithDictionary:model];
    [expectedModel setObject:[NSNumber numberWithInteger:resource.primaryKeyType] forKey:resource.primaryKey];
    
    XCTAssert([resource.model isEqualToDictionary:expectedModel], @"The resource model must match the passed model plus the primary key");
}

- (void)testImplicitPrimaryKeyInModel
{
    TGRESTResource *resource;
    NSDictionary *model = @{
                            @"id": [NSNumber numberWithInteger:TGPropertyTypeString],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString]
                            };
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:@"test" model:model], @"The resource construction must not throw an exception.");
    
    XCTAssert([resource.model isEqualToDictionary:model], @"The resource model must match the model that was provided exactly");
    XCTAssert([resource.primaryKey isEqualToString:@"id"], @"The primary key must match the default value");
    XCTAssert(resource.primaryKeyType == TGPropertyTypeString, @"The primary key type must match the provided string type in the model, not the default integer value");
}

- (void)testMultipleParentResources
{
    NSArray *parents = [TGTestFactory randomModelTestResourcesWithCount:5];
    TGRESTResource *resource;
    NSDictionary *model = @{
                            @"id": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString]
                            };
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:@"test" model:model actions:TGResourceRESTActionsGET primaryKey:nil parentResources:parents], @"The resource construction must not throw an exception.");
    
    NSMutableDictionary *expectedModel = [NSMutableDictionary dictionaryWithDictionary:model];
    NSMutableDictionary *expectedFKeys = [NSMutableDictionary new];
    for (TGRESTResource *parent in parents) {
        NSString *defaultFKey = [NSString stringWithFormat:@"%@_id", parent.name];
        [expectedModel setObject:[NSNumber numberWithInteger:parent.primaryKeyType] forKey:defaultFKey];
        [expectedFKeys setObject:defaultFKey forKey:parent.name];
    }
    
    XCTAssert([resource.model isEqualToDictionary:expectedModel], @"The model must equal the passed model plus the default foreign keys for the parent objects");
    XCTAssert([resource.foreignKeys isEqualToDictionary:expectedFKeys], @"The foreignKeys must have the primary keys and names of all of the parent resources");
}

- (void)testDefaultForeignKeyInModel
{
    TGRESTResource *parent = [TGTestFactory randomModelTestResource];
    NSString *defaultFKey = [NSString stringWithFormat:@"%@_id", parent.name];
    TGRESTResource *resource;
    NSDictionary *model = @{
                            @"id": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                            defaultFKey: [NSNumber numberWithInteger:parent.primaryKeyType]
                            };
    
    XCTAssertNoThrow(resource = [TGRESTResource newResourceWithName:@"test" model:model actions:TGResourceRESTActionsGET primaryKey:nil parentResources:@[parent]], @"The resource construction must not throw an exception.");
    
    NSDictionary *expectedFKeyDict = @{
                                       parent.name: defaultFKey
                                       };
    XCTAssert([resource.model isEqualToDictionary:model], @"The model must equal the passed model exactly since we specified the default id and foreign key name");
    XCTAssert([resource.foreignKeys isEqualToDictionary:expectedFKeyDict], @"The foreignKeys dict must match the expected dictionary");
}

- (void)testRelationProperties
{
    TGRESTResource *parentResource = [TGTestFactory testResource];
    XCTAssert(parentResource.childResources.count == 0, @"The parent must not have any child resources");

    TGRESTResource *childResource;
    NSDictionary *model = @{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]};
    
    XCTAssertNoThrow(childResource = [TGRESTResource newResourceWithName:@"child" model:model actions:TGResourceRESTActionsGET primaryKey:nil parentResources:@[parentResource]], @"There must not be an exception creating the child resource.");
    
    XCTAssert([childResource.parentResources containsObject:parentResource], @"Child resource must have parent resource in its parent array");
    XCTAssert([parentResource.childResources containsObject:childResource], @"Parent resource must have child resource in its child array");
    XCTAssert(childResource.parentResources.count == 1, @"The child must have one parent");
    XCTAssert(parentResource.childResources.count == 1, @"The parent must have one child");
}

#pragma mark - Negative tests

- (void)testPrimaryKeyNotInModel
{
    TGRESTResource *resource;
    NSString *primaryKey = @"person_id";
    NSDictionary *model = @{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]};
    
    XCTAssertThrows(resource = [TGRESTResource newResourceWithName:@"person" model:model actions:TGResourceRESTActionsPOST primaryKey:primaryKey], @"Including a custom primary key name that is not in the model must throw an exception");
    XCTAssertNil(resource, @"The resource must be nil");
}

- (void)testPrimaryKeyImplictlySetToInvalidType
{
    TGRESTResource *resource;
    NSDictionary *model = @{
                            @"id": [NSNumber numberWithInteger:TGPropertyTypeBlob],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString]
                            };
    
    XCTAssertThrows(resource = [TGRESTResource newResourceWithName:@"person" model:model], @"Setting the default primary key id in the model to a data type other than string or integer must generate an exception");
    XCTAssertNil(resource, @"The resource must be nil");
}

- (void)testPrimaryKeyExplictlySetToInvalidType
{
    TGRESTResource *resource;
    NSString *primaryKey = @"person_id";
    NSDictionary *model = @{
                            @"person_id": [NSNumber numberWithInteger:TGPropertyTypeBlob],
                            @"name": [NSNumber numberWithInteger:TGPropertyTypeString]
                            };
    
    XCTAssertThrows(resource = [TGRESTResource newResourceWithName:@"person" model:model actions:TGResourceRESTActionsPOST primaryKey:primaryKey], @"Setting the primary key in the model explicitly with an unsupported type must generate an exception");
    XCTAssertNil(resource, @"The resource must be nil");
}

- (void)testForeignKeyParentNameMismatch
{
    
}

- (void)testExplictForeignKeyInModelTypeMismatch
{
    
}

- (void)testPrimaryKeyEmptyString
{
    
}

- (void)testForeignKeyEmptyString
{
    
}

- (void)testModelEmptyString
{
    
}

- (void)testModelTypeNotInEnum
{
    
}

- (void)testAddDifferentResourceWithExistingName
{
    
}

- (void)testAddExistingResource
{
    
}



@end
