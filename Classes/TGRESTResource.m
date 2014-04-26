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
        self.model = @{@"id": [NSNumber numberWithInteger:TGPropertyTypeInteger]};
        self.primaryKey = @"id";
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
                         foreignKeys:nil];
}

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                        foreignKeys:(NSDictionary *)fkeys
{
    NSParameterAssert(name);
    NSParameterAssert(model);
    
    TGRESTResource *resource = [TGRESTResource new];
    
    resource.name = name;
    resource.actions = actions;
    
    if (key) {
        if (!model[key]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Primary key not found in model"
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
        NSMutableDictionary *mergeModel = [NSMutableDictionary dictionaryWithDictionary:resource.model];
        NSMutableDictionary *userModel = [NSMutableDictionary dictionaryWithDictionary:model];
        [userModel removeObjectForKey:resource.primaryKey];
        [mergeModel addEntriesFromDictionary:userModel];
        resource.model = [NSDictionary dictionaryWithDictionary:mergeModel];
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
