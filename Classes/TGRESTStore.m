//
//  TGRESTAbstractStore.m
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import "TGRESTStore.h"

NSString * const TGRESTStoreErrorDomain = @"TGRESTStoreErrorDomain";
NSUInteger const TGRESTStoreUnknownErrorCode = 1000;
NSUInteger const TGRESTStoreObjectAlreadyDeletedErrorCode = 1001;
NSUInteger const TGRESTStoreObjectNotFoundErrorCode = 1002;
NSUInteger const TGRESTStoreBadRequestErrorCode = 1003;

@interface TGRESTStore ()

@property (nonatomic, copy, readwrite) NSString *name;

@end

@implementation TGRESTStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.name = NSStringFromClass([self class]);
    }
    
    return self;
}

- (NSUInteger)countOfObjectsForResource:(TGRESTResource *)resource
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSDictionary *)getDataForObjectOfResource:(TGRESTResource *)resource
                              withPrimaryKey:(NSString *)primaryKey
                                       error:(NSError * __autoreleasing *)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSArray *)getDataForObjectsOfResource:(TGRESTResource *)resource
                                  withParent:(TGRESTResource *)parent
                            parentPrimaryKey:(NSString *)key
                                       error:(NSError * __autoreleasing *)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSArray *)getAllObjectsForResource:(TGRESTResource *)resource
                                error:(NSError * __autoreleasing *)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource
                              withProperties:(NSDictionary *)properties
                                       error:(NSError * __autoreleasing *)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSDictionary *)modifyObjectOfResource:(TGRESTResource *)resource
                          withPrimaryKey:(NSString *)primaryKey
                          withProperties:(NSDictionary *)properties
                                   error:(NSError * __autoreleasing *)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)deleteObjectOfResource:(TGRESTResource *)resource
                withPrimaryKey:(NSString *)primaryKey
                         error:(NSError * __autoreleasing *)error
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)addResource:(TGRESTResource *)resource
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)dropResource:(TGRESTResource *)resource
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
