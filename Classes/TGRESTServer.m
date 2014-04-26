//
//  TGRESTServer.m
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import "TGRESTServer.h"
#import "TGRESTResource.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerDataRequest.h>
#import "TGPrivateFunctions.h"
#import "TGRESTServer_TGRESTServerPrivate.h"

NSString * const TGLatencyRangeMinimumOptionKey = @"TGLatencyRangeMinimumOptionKey";
NSString * const TGLatencyRangeMaximumOptionKey = @"TGLatencyRangeMaximumOptionKey";
NSString * const TGWebServerPortNumberOptionKey = @"TGWebServerPortNumberOptionKey";

NSString * const TGServerDidStartNotification = @"TGServerDidStartNotification";
NSString * const TGServerDidShutdownNotification = @"TGServerDidShutdownNotification";

NSString * const TGRESTServerErrorDomain = @"TGRESTServerErrorDomain";
NSUInteger const TGRESTServerObjectDeletedErrorCode = 100;
NSUInteger const TGRESTServerObjectNotFoundErrorCode = 101;
NSUInteger const TGRESTServerUnknownErrorCode = 102;
NSUInteger const TGRESTServerBadRequestErrorCode = 103;

@implementation TGRESTServer

#pragma mark - Initialization

+ (instancetype)sharedServer
{
    static dispatch_once_t onceQueue;
    static TGRESTServer *sharedServer = nil;
    
    dispatch_once(&onceQueue, ^{ sharedServer = [[self alloc] init]; });
    return sharedServer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.webServer = [[GCDWebServer alloc] init];
        self.resources = [NSMutableSet new];
        self.inMemoryDatastore = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark - Override getters

- (BOOL)isRunning
{
    return self.webServer.isRunning;
}

#pragma mark - Server control

- (void)startServerWithOptions:(NSDictionary *)options
{
    NSUInteger serverPort;
    
    if (options[TGWebServerPortNumberOptionKey]) {
        serverPort = [options[TGWebServerPortNumberOptionKey] integerValue];
    } else {
        serverPort = 8888;
    }
    
    [options[TGWebServerPortNumberOptionKey] integerValue];
    self.latencyMin = [options[TGLatencyRangeMinimumOptionKey] floatValue];
    self.latencyMax = [options[TGLatencyRangeMaximumOptionKey] floatValue];
    [self.webServer startWithPort:serverPort bonjourName:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TGServerDidStartNotification object:self];
}

- (void)stopServer
{
    [self removeAllResourcesWithData:YES];
    [self.webServer stop];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TGServerDidShutdownNotification object:self];
}

#pragma mark - Resources

- (NSSet *)currentResources
{
    return [NSSet setWithSet:self.resources];
}

- (void)addResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    [self.inMemoryDatastore setObject:[NSMutableDictionary new] forKey:resource.name];
    
    if (resource.actions & TGResourceRESTActionsGET) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:[NSString stringWithFormat:@"^/(%@)", resource.name]
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   if ([lastPathComponent isEqualToString:resource.name]) {
                                       NSError *error;
                                       NSArray *allData = [strongSelf getAllDataForResource:resource error:&error];
                                       if (error) {
                                           return [TGRESTServer errorResponseBuilderWithError:error];
                                       }
                                       return [GCDWebServerDataResponse responseWithJSONObject:allData];
                                   } else {
                                       NSError *error;
                                       NSDictionary *resourceResponse = [strongSelf getDataForResource:resource withPrimaryKey:lastPathComponent error:&error];
                                       if (error) {
                                           return [TGRESTServer errorResponseBuilderWithError:error];
                                       }
                                       return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
                                   }
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsPOST) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"POST"
                                  pathRegex:[NSString stringWithFormat:@"^/(%@)", resource.name]
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
                                   NSDictionary *body;
                                   if ([dataRequest.contentType hasPrefix:@"application/json"]) {
                                       NSError *jsonError;
                                       body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:NSJSONReadingAllowFragments error:&jsonError];
                                       if (jsonError) {
                                           return [GCDWebServerResponse responseWithStatusCode:400];
                                       }
                                   } else if ([dataRequest.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
                                       return [GCDWebServerResponse responseWithStatusCode:400];
                                   }
                                   NSError *error;
                                   NSDictionary *newObject = [strongSelf createNewObjectForResource:resource withDictionary:body error:&error];
                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:newObject];
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsDELETE) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"DELETE"
                                  pathRegex:[NSString stringWithFormat:@"^/(%@)", resource.name]
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   if ([lastPathComponent isEqualToString:resource.name]) {
                                       return [GCDWebServerResponse responseWithStatusCode:403];
                                   }
                                   NSError *error;
                                   [strongSelf deleteResource:resource withPrimaryKey:lastPathComponent error:&error];
                                   
                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerResponse responseWithStatusCode:204];
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsPUT) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"PUT"
                                  pathRegex:[NSString stringWithFormat:@"^/(%@)", resource.name]
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   if ([lastPathComponent isEqualToString:resource.name]) {
                                       return [GCDWebServerResponse responseWithStatusCode:403];
                                   }
                                   GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
                                   NSDictionary *body;
                                   if ([dataRequest.contentType hasPrefix:@"application/json"]) {
                                       NSError *jsonError;
                                       body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:NSJSONReadingAllowFragments error:&jsonError];
                                       if (jsonError) {
                                           return [GCDWebServerResponse responseWithStatusCode:400];
                                       }
                                   } else if ([dataRequest.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
                                       return [GCDWebServerResponse responseWithStatusCode:400];
                                   }
                                   
                                   NSError *error;
                                   NSDictionary *resourceResponse = [strongSelf modifyResource:resource withPrimaryKey:lastPathComponent withDictionary:body error:&error];
                                   
                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
                               }];
    }
    
    [self.resources addObject:resource];
}

- (void)removeResource:(TGRESTResource *)resource withData:(BOOL)removeData
{
    
}

- (void)removeAllResourcesWithData:(BOOL)removeData
{
    [self.webServer removeAllHandlers];
    [self.resources removeAllObjects];
    
    if (removeData) {
        self.inMemoryDatastore = [NSMutableDictionary new];
    }
}

- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource
{
    return [self allObjectsForResource:resource].count;
}

- (NSArray *)allObjectsForResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    if (![self.currentResources containsObject:resource]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Primary keys must be of text or integer type only"
                                     userInfo:nil];
    }
    
    return [self getAllDataForResource:resource error:nil];
}

- (void)addData:(NSArray *)data forResource:(TGRESTResource *)resource
{
    for (NSDictionary *objectDictionary in data) {
        NSError *error;
        [self createNewObjectForResource:resource withDictionary:objectDictionary error:&error];
        if (error) {
            NSLog(@"Error creating object %@", objectDictionary);
        }
    }
}

#pragma mark - Private

+ (GCDWebServerResponse *)errorResponseBuilderWithError:(NSError *)error
{
    NSParameterAssert(error);
    
    if (error.code == TGRESTServerObjectDeletedErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:410];
    } else if (error.code == TGRESTServerObjectNotFoundErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:404];
    } else if (error.code == TGRESTServerBadRequestErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:400];
    } else {
        return [GCDWebServerResponse responseWithStatusCode:500];
    }
}

- (NSDictionary *)getDataForResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);

    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    NSDictionary *object;
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        if (objects[[NSNumber numberWithInteger:[pk integerValue]]] == [NSNull null]) {
            if (error) {
                *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerObjectDeletedErrorCode userInfo:nil];
            }
            return nil;
        }
        object = objects[[NSNumber numberWithInteger:[pk integerValue]]];
    } else {
        if (objects[pk] == [NSNull null]) {
            if (error) {
                *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerObjectDeletedErrorCode userInfo:nil];
            }
            return nil;
        }
        object = objects[pk];
    }
    
    if (!object && error) {
        *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerObjectNotFoundErrorCode userInfo:nil];
    }
    
    return object;
}

- (NSArray *)getAllDataForResource:(TGRESTResource *)resource error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);

    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    if (!objects) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerUnknownErrorCode userInfo:nil];
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

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource withDictionary:(NSDictionary *)dictionary error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    
    if (!dictionary || dictionary.allKeys.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerBadRequestErrorCode userInfo:nil];
        }
        return nil;
    }
    
    NSMutableDictionary *newObjectStub = [NSMutableDictionary new];
    
    for (NSString *key in resource.model.allKeys) {
        if (dictionary[key]) {
            [newObjectStub setObject:dictionary[key] forKey:key];
        }
    }
    
    if (newObjectStub.allKeys.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerBadRequestErrorCode userInfo:nil];
        }
        return nil;
    }
    
    NSMutableDictionary *resourceDictionary = [self.inMemoryDatastore objectForKey:resource.name];
    if (!resourceDictionary) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerUnknownErrorCode userInfo:nil];
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
    [newObjectStub setObject:newPrimaryKeyObject forKey:resource.primaryKey];
    NSDictionary *newObjectDictionary = [NSDictionary dictionaryWithDictionary:newObjectStub];
    [resourceDictionary setObject:newObjectDictionary forKey:newPrimaryKeyObject];
    return newObjectDictionary;
}

- (NSDictionary *)modifyResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk withDictionary:(NSDictionary *)dictionary error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    
    if (!dictionary || dictionary.allKeys.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerBadRequestErrorCode userInfo:nil];
        }
        return nil;
    }
    NSError *getError;
    NSDictionary *object = [self getDataForResource:resource withPrimaryKey:pk error:&getError];
    if (getError) {
        if (error) {
            *error = getError;
        }
        return nil;
    }
    
    NSMutableDictionary *newDict = [NSMutableDictionary new];
    
    for (NSString *key in resource.model.allKeys) {
        if (![key isEqualToString:resource.primaryKey]) {
            if (dictionary[key]) {
                [newDict setObject:dictionary[key] forKey:key];
            }
        }
    }
    
    if (newDict.allKeys.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerBadRequestErrorCode userInfo:nil];
        }
    }
    
    NSMutableDictionary *mergeDict = [NSMutableDictionary dictionaryWithDictionary:object];
    [mergeDict addEntriesFromDictionary:newDict];
    NSDictionary *updatedObject = [NSDictionary dictionaryWithDictionary:mergeDict];
    
    NSMutableDictionary *resourceDictionary = [self.inMemoryDatastore objectForKey:resource.name];
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        [resourceDictionary setObject:updatedObject forKey:[NSNumber numberWithInteger:[pk integerValue]]];
    } else {
        [resourceDictionary setObject:updatedObject forKey:pk];
    }
    
    return updatedObject;
}

- (void)deleteResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    
    NSMutableDictionary *objects = self.inMemoryDatastore[resource.name];
    id objectKey;
    if (resource.primaryKeyType == TGPropertyTypeInteger) {
        objectKey = [NSNumber numberWithInteger:[pk integerValue]];
    } else {
        objectKey = pk;
    }
    
    if (objects[objectKey] == [NSNull null]) {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerObjectDeletedErrorCode userInfo:nil];
        }
    } else {
        NSDictionary *object = objects[objectKey];
        
        if (!object) {
            if (error) {
                *error = [NSError errorWithDomain:TGRESTServerErrorDomain code:TGRESTServerObjectNotFoundErrorCode userInfo:nil];
            }
        } else {
            [objects setObject:[NSNull null] forKey:objectKey];
        }
    }
}


@end
