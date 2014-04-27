//
//  TGRESTInMemoryStore.m
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import "TGRESTInMemoryStore.h"
#import "TGRESTResource.h"

@interface TGRESTInMemoryStore ()

@property (atomic, strong) NSMutableDictionary *inMemoryDatastore;

@end

@implementation TGRESTInMemoryStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inMemoryDatastore = [NSMutableDictionary new];
    }
    
    return self;
}

- (NSUInteger)countOfObjectsForResource:(TGRESTResource *)resource
{
    return [[self getAllObjectsForResource:resource error:nil] count];
}

- (NSDictionary *)getDataForObjectOfResource:(TGRESTResource *)resource
                              withPrimaryKey:(NSString *)primaryKey
                                       error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(primaryKey);
    NSParameterAssert(resource);
    
    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    NSDictionary *object;
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        if (objects[[NSNumber numberWithInteger:[primaryKey integerValue]]] == [NSNull null]) {
            if (error) {
                *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreObjectAlreadyDeletedErrorCode userInfo:nil];
            }
            return nil;
        }
        object = objects[[NSNumber numberWithInteger:[primaryKey integerValue]]];
    } else {
        if (objects[primaryKey] == [NSNull null]) {
            if (error) {
                *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreObjectAlreadyDeletedErrorCode userInfo:nil];
            }
            return nil;
        }
        object = objects[primaryKey];
    }
    
    if (!object && error) {
        *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreObjectNotFoundErrorCode userInfo:nil];
    }
    
    return object;
}

- (NSArray *)getDataForObjectsOfResource:(TGRESTResource *)resource
                                  withParent:(TGRESTResource *)parent
                            parentPrimaryKey:(NSString *)key
                                       error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    NSParameterAssert(parent);
    NSParameterAssert(key);
    
    NSError *lookup;
    [self getDataForObjectOfResource:resource withPrimaryKey:key error:&lookup];
    
    if (lookup) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreObjectNotFoundErrorCode userInfo:nil];
        }
        
        return nil;
    }
    
    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    id normalizedKey;
    if (parent.primaryKeyType == TGPropertyTypeInteger) {
        normalizedKey = [NSNumber numberWithInteger:[key integerValue]];
    } else {
        normalizedKey = key;
    }
    NSPredicate *matchPredicate = [NSPredicate predicateWithFormat:@"self.%@ == %@", resource.foreignKeys[parent.name], normalizedKey];
    NSMutableArray *returnArray = [NSMutableArray new];
    
    for (NSDictionary *object in objects.allValues) {
        if ([matchPredicate evaluateWithObject:object]) {
            [returnArray addObject:object];
        }
    }
    
    return [NSArray arrayWithArray:returnArray];
}

- (NSArray *)getAllObjectsForResource:(TGRESTResource *)resource
                                error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);

    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    if (!objects) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreUnknownErrorCode userInfo:nil];
        }
        return nil;
    } else if (objects.count == 0) {
        return @[];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self != %@", [NSNull null]];
    NSSet *filteredKeys = [objects keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return [predicate evaluateWithObject:obj];
    }];
    NSArray *filteredObjects = [objects objectsForKeys:[filteredKeys allObjects] notFoundMarker:@""];
    return [filteredObjects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:resource.primaryKey ascending:YES]]];
}

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource
                              withProperties:(NSDictionary *)properties
                                       error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(properties);
    NSParameterAssert(resource);
    
    NSMutableDictionary *resourceDictionary = [self.inMemoryDatastore objectForKey:resource.name];
    if (!resourceDictionary) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreUnknownErrorCode userInfo:nil];
        }
        return nil;
    }
    NSUInteger newPrimaryKey = [resourceDictionary allKeys].count + 1;
    id newPrimaryKeyObject;
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        newPrimaryKeyObject = [NSNumber numberWithInteger:newPrimaryKey];
    } else {
        newPrimaryKeyObject = [NSString stringWithFormat:@"%lu", (unsigned long)newPrimaryKey];
    }
    
    NSMutableDictionary *propertyDictionary = [NSMutableDictionary dictionaryWithDictionary:properties];
    [propertyDictionary setObject:newPrimaryKeyObject forKey:resource.primaryKey];
    NSDictionary *newObjectDictionary = [NSDictionary dictionaryWithDictionary:propertyDictionary];
    [resourceDictionary setObject:newObjectDictionary forKey:newPrimaryKeyObject];
    return newObjectDictionary;
}

- (NSDictionary *)modifyObjectOfResource:(TGRESTResource *)resource
                          withPrimaryKey:(NSString *)primaryKey
                          withProperties:(NSDictionary *)properties
                                   error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(primaryKey);
    NSParameterAssert(resource);
    NSParameterAssert(properties);
    
    NSError *getError;
    NSDictionary *object = [self getDataForObjectOfResource:resource withPrimaryKey:primaryKey error:&getError];
    if (getError) {
        if (error) {
            *error = getError;
        }
        return nil;
    }
    
    NSMutableDictionary *mergeDict = [NSMutableDictionary dictionaryWithDictionary:object];
    [mergeDict addEntriesFromDictionary:properties];
    NSDictionary *updatedObject = [NSDictionary dictionaryWithDictionary:mergeDict];
    
    NSMutableDictionary *resourceDictionary = [self.inMemoryDatastore objectForKey:resource.name];
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        [resourceDictionary setObject:updatedObject forKey:[NSNumber numberWithInteger:[primaryKey integerValue]]];
    } else {
        [resourceDictionary setObject:updatedObject forKey:primaryKey];
    }
    
    return updatedObject;
}

- (void)deleteObjectOfResource:(TGRESTResource *)resource
                withPrimaryKey:(NSString *)primaryKey
                         error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    NSParameterAssert(primaryKey);

    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    id objectKey;
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        objectKey = [NSNumber numberWithInteger:[primaryKey integerValue]];
    } else {
        objectKey = primaryKey;
    }
    
    if (objects[objectKey] == [NSNull null]) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreObjectAlreadyDeletedErrorCode userInfo:nil];
        }
    } else {
        NSDictionary *object = objects[objectKey];
        
        if (!object) {
            if (error) {
                *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreObjectNotFoundErrorCode userInfo:nil];
            }
        } else {
            [objects setObject:[NSNull null] forKey:objectKey];
        }
    }
}

- (void)addResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);

    [self.inMemoryDatastore setObject:[NSMutableDictionary new] forKey:resource.name];
}

- (void)dropResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    [self.inMemoryDatastore removeObjectForKey:resource.name];
}

@end
