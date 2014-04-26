//
//  TGRESTResource.m
//  Tests
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import "TGRESTResource.h"

@interface TGRESTResource ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSDictionary *model;
@property (nonatomic, copy, readwrite) NSString *primaryKey;
@property (nonatomic, copy, readwrite) NSArray *parentResources;
@property (nonatomic, copy, readwrite) NSArray *childResources;
@property (nonatomic, copy, readwrite) NSDictionary *foreignKeys;
@property (nonatomic, assign, readwrite) TGPropertyType primaryKeyType;
@property (nonatomic, assign, readwrite) TGResourceRESTActions actions;

@end

@implementation TGRESTResource

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.name = @"";
        self.model = @{};
        self.primaryKey = @"id";
        self.parentResources = @[];
        
        self.foreignKeys = @{};
        self.primaryKeyType = TGPropertyTypeInteger;
        self.actions = TGResourceRESTActionsGET;
    }
    
    return self;
}

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
{    
    return [self newResourceWithName:name
                               model:model
                             actions:TGResourceRESTActionsGET | TGResourceRESTActionsPOST | TGResourceRESTActionsPUT | TGResourceRESTActionsDELETE
                          primaryKey:nil
                     parentResources:nil
                         foreignKeys:nil];
}

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
{
    return [self newResourceWithName:name
                               model:model
                             actions:actions
                          primaryKey:key
                         parentResources:nil
                         foreignKeys:nil];
}

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                    parentResources:(NSArray *)parents
{
    return [self newResourceWithName:name
                               model:model
                             actions:actions
                          primaryKey:key
                     parentResources:parents
                         foreignKeys:nil];
}

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                    parentResources:(NSArray *)parents
                        foreignKeys:(NSDictionary *)fkeys
{
    NSParameterAssert(name);
    NSParameterAssert(model);
    
    TGRESTResource *resource = [TGRESTResource new];
    
    resource.name = name;
    resource.actions = actions;
    
    NSMutableDictionary *mergeModel = [NSMutableDictionary new];
    
    if (key) {
        if (!model[key]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"Primary key %@ not found in model", key]
                                         userInfo:nil];
        } else {
            TGPropertyType primaryKeyType = [model[key] integerValue];
            if (primaryKeyType == TGPropertyTypeString || primaryKeyType == TGPropertyTypeInteger) {
                resource.primaryKey = key;
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"Primary keys must be of text or integer type only"
                                             userInfo:nil];
            }
        }
    } else {
        NSNumber *existingModelIDProperty = model[@"id"];
        if (!existingModelIDProperty) {
            [mergeModel setObject:[NSNumber numberWithInteger:TGPropertyTypeInteger] forKey:resource.primaryKey];
        } else if ([existingModelIDProperty integerValue] != TGPropertyTypeInteger && [existingModelIDProperty integerValue] != TGPropertyTypeString) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"The default primary key of 'id' is set to a type that is not text or integer type.  If you want to use 'id' as your primary key give it a valid type in the model or if you want to use a different primary key then set the primary key name explicitly in the constructor."
                                         userInfo:nil];
        }
    }
    
    [mergeModel addEntriesFromDictionary:model];
    
    NSMutableArray *validParents = [NSMutableArray new];
    NSMutableDictionary *foreignKeyBuilder = [NSMutableDictionary new];
    
    for (id object in parents) {
        if (![object isKindOfClass:[TGRESTResource class]]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Parent resources must be of TGRESTResource class type"
                                         userInfo:nil];
        }
        TGRESTResource *parent = (TGRESTResource *)object;
        if (fkeys[parent.name] && resource.model[fkeys[parent.name]]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"Your model already has a key named %@, you cannot use it as a foreign key", fkeys[parent.name]]
                                         userInfo:nil];
        } else if (!fkeys[parent.name] && resource.model[[NSString stringWithFormat:@"%@_id", parent.name]]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"Your have not specified a foreign key for parent named %@ but the default foreign key name of %@_id is already specified in your model.  Either delete this from your model or specify a custom foreign key identifier for this parent.", parent.name, parent.name]
                                         userInfo:nil];
        } else {
            [validParents addObject:object];
            if (fkeys[parent.name]) {
                [foreignKeyBuilder setObject:fkeys[parent.name] forKey:parent.name];
                if (parent.primaryKeyType == TGPropertyTypeString) {
                    [mergeModel setObject:[NSNumber numberWithInteger:TGPropertyTypeString] forKey:fkeys[parent.name]];
                } else {
                    [mergeModel setObject:[NSNumber numberWithInteger:TGPropertyTypeInteger] forKey:fkeys[parent.name]];
                }
            } else {
                NSString *defaultForeignKey = [NSString stringWithFormat:@"%@_id", parent.name];
                [foreignKeyBuilder setObject:defaultForeignKey forKey:parent.name];
                if (parent.primaryKeyType == TGPropertyTypeString) {
                    [mergeModel setObject:[NSNumber numberWithInteger:TGPropertyTypeString] forKey:defaultForeignKey];
                } else {
                    [mergeModel setObject:[NSNumber numberWithInteger:TGPropertyTypeInteger] forKey:defaultForeignKey];
                }
            }
        }
    }
    
    resource.parentResources = [NSArray arrayWithArray:validParents];
    resource.model = [NSDictionary dictionaryWithDictionary:mergeModel];
    resource.primaryKeyType = [resource.model[resource.primaryKey] integerValue];
    resource.foreignKeys = [NSDictionary dictionaryWithDictionary:foreignKeyBuilder];
    
    for (TGRESTResource *parentResource in resource.parentResources) {
        NSMutableArray *newChildren = [NSMutableArray arrayWithArray:parentResource.childResources];
        [newChildren addObject:resource];
        [parentResource setValue:[NSArray arrayWithArray:newChildren] forKey:@"childResources"];
    }
    
    return resource;
}

#pragma mark - Private

- (NSDictionary *)sqliteModel
{
    NSMutableDictionary *sqlite3Model = [NSMutableDictionary new];
    for (NSString *key in [self.model allKeys]) {
        NSNumber *value = self.model[key];
        if ([value integerValue] == TGPropertyTypeString) {
            [sqlite3Model setObject:@"TEXT" forKey:key];
        } else if ([value integerValue] == TGPropertyTypeInteger) {
            [sqlite3Model setObject:@"INTEGER" forKey:key];
        } else if ([value integerValue] == TGPropertyTypeFloatingPoint) {
            [sqlite3Model setObject:@"REAL" forKey:key];
        } else if ([value integerValue] == TGPropertyTypeBlob) {
            [sqlite3Model setObject:@"BLOB" forKey:key];
        }
    }    
    return [NSDictionary dictionaryWithDictionary:sqlite3Model];
}

@end
