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
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import "TGPrivateFunctions.h"

NSString * const TGLatencyRangeMinimumOptionKey = @"TGLatencyRangeMinimumOptionKey";
NSString * const TGLatencyRangeMaximumOptionKey = @"TGLatencyRangeMaximumOptionKey";
NSString * const TGPersistenceNameOptionKey = @"TGPersistenceNameOptionKey";
NSString * const TGWebServerPortNumberOptionKey = @"TGWebServerPortNumberOptionKey";

NSString * const TGServerDidStartNotification = @"TGServerDidStartNotification";
NSString * const TGServerDidShutdownNotification = @"TGServerDidShutdownNotification";

NSString * const TGRESTServerErrorDomain = @"TGRESTServerErrorDomain";
NSUInteger const TGRESTServerObjectDeletedErrorCode = 100;
NSUInteger const TGRESTServerObjectNotFoundErrorCode = 101;
NSUInteger const TGRESTServerUnknownErrorCode = 102;
NSUInteger const TGRESTServerBadRequestErrorCode = 103;

@interface TGRESTServer ()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, assign) CGFloat latencyMin;
@property (nonatomic, assign) CGFloat latencyMax;
@property (nonatomic, strong) NSMutableSet *resources;
@property (atomic, strong) NSMutableDictionary *inMemoryDatastore;
@property (nonatomic, assign, readwrite, getter = isPersisting) BOOL persisting;

@end

@implementation TGRESTServer

#pragma mark - Initialization

+ (instancetype)sharedServer
{
    static dispatch_once_t onceQueue;
    static TGRESTServer *sharedServer = nil;
    
    dispatch_once(&onceQueue, ^{ sharedServer = [[self alloc] init]; });
    return sharedServer;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.webServer = [[GCDWebServer alloc] init];
        self.resources = [NSMutableSet new];
        self.inMemoryDatastore = [NSMutableDictionary new];
        self.persisting = NO;
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
    
    if (options[TGPersistenceNameOptionKey]) {
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[NSString stringWithFormat:@"%@/%@.sqlite", TGApplicationDataDirectory(), options[TGPersistenceNameOptionKey]] flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
        self.persisting = YES;
    } else {
        self.dbQueue = nil;
        self.persisting = NO;
    }
    
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
    
    if (self.isPersisting) {
        NSDictionary *newModel = [resource valueForKey:@"sqliteModel"];
        __block BOOL resetTable = NO;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *tableInfo = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", resource.name]];
            if ([tableInfo columnCount] > 0) {
                NSMutableDictionary *existingModel = [NSMutableDictionary new];
                while ([tableInfo next]) {
                    [existingModel setObject:[tableInfo stringForColumn:@"type"] forKey:[tableInfo stringForColumn:@"name"]];
                }
                if (![newModel isEqualToDictionary:existingModel]) {
                    resetTable = YES;
                }
            } else {
                resetTable = YES;
            }
            [tableInfo close];
        }];
        
        if (resetTable) {
            NSMutableString *columnString = [NSMutableString new];
            for (NSString *key in [newModel allKeys]) {
                [columnString appendString:[NSString stringWithFormat:@"\"%@\" %@, ", key, newModel[key]]];
            }
            
            [columnString deleteCharactersInRange:NSMakeRange(columnString.length - 2, 2)];
            
            [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                if (![db executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", resource.name]]) {
                    NSLog(@"Error: %@", [db lastError]);
                    *rollback = YES;
                    return;
                }
                
                if (![db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE %@ (%@)", resource.name, columnString]]) {
                    NSLog(@"Error: %@", [db lastError]);
                    *rollback = YES;
                    return;
                }
            }];
        }
    } else {
        [self.inMemoryDatastore setObject:[NSMutableDictionary new] forKey:resource.name];
    }
    
    if (resource.actions & TGResourceRESTActionsGET) {
        __weak typeof(self) weakSelf = self;
        
        for (NSString *route in resource.routes) {
            [self.webServer addHandlerForMethod:@"GET"
                                      pathRegex:[NSString stringWithFormat:@"^/(%@)", route]
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
    }
    
    if (resource.actions & TGResourceRESTActionsPOST) {
        __weak typeof(self) weakSelf = self;
        
        for (NSString *route in resource.routes) {
            [self.webServer addHandlerForMethod:@"POST"
                                      pathRegex:[NSString stringWithFormat:@"^/(%@)", route]
                                   requestClass:[GCDWebServerDataRequest class]
                                   processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       NSDictionary *body = [(GCDWebServerDataRequest*)request jsonObject];
                                       NSError *error;
                                       NSDictionary *newObject = [strongSelf createNewObjectForResource:resource withDictionary:body error:&error];
                                       if (error) {
                                           return [TGRESTServer errorResponseBuilderWithError:error];
                                       }
                                       return [GCDWebServerDataResponse responseWithJSONObject:newObject];
                                   }];
        }
    }
    
    if (resource.actions & TGResourceRESTActionsDELETE) {
        __weak typeof(self) weakSelf = self;
        
        for (NSString *route in resource.routes) {
            [self.webServer addHandlerForMethod:@"DELETE"
                                      pathRegex:[NSString stringWithFormat:@"^/(%@)", route]
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
    }
    
    if (resource.actions & TGResourceRESTActionsPUT) {
        __weak typeof(self) weakSelf = self;
        
        for (NSString *route in resource.routes) {
            [self.webServer addHandlerForMethod:@"PUT"
                                      pathRegex:[NSString stringWithFormat:@"^/(%@)", route]
                                   requestClass:[GCDWebServerDataRequest class]
                                   processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       NSString *lastPathComponent = request.URL.lastPathComponent;
                                       if ([lastPathComponent isEqualToString:resource.name]) {
                                           return [GCDWebServerResponse responseWithStatusCode:403];
                                       }
                                       NSDictionary *body = [(GCDWebServerDataRequest*)request jsonObject];
                                       NSError *error;
                                       NSDictionary *resourceResponse = [strongSelf modifyResource:resource withPrimaryKey:lastPathComponent withDictionary:body error:&error];
                                       
                                       if (error) {
                                           return [TGRESTServer errorResponseBuilderWithError:error];
                                       }
                                       return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
                                   }];
        }
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
        if (self.isPersisting) {
            NSError *error;
            NSString *path = [self.dbQueue.path copy];
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error) {
                NSLog(@"Error deleting sqlite store! %@", error);
            }
            self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:path flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
        } else {
            self.inMemoryDatastore = [NSMutableDictionary new];
        }
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

    if (self.isPersisting) {
        __block NSMutableDictionary *returnDictionary = [NSMutableDictionary new];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *results = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %@", resource.name, resource.primaryKey, pk]];
            for (NSString *key in resource.model) {
                [returnDictionary setObject:[results objectForColumnName:key] forKey:key];
            }
            [results close];
        }];
        if (returnDictionary.allKeys.count == 0) {
            return nil;
        } else {
            return [NSDictionary dictionaryWithDictionary:returnDictionary];
        }
    } else {
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
    
    return nil;
}

- (NSArray *)getAllDataForResource:(TGRESTResource *)resource error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);

    if (self.isPersisting) {
        __block NSMutableArray *returnArray = [NSMutableArray new];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *results = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@", resource.name]];
            while ([results next]) {
                NSMutableDictionary *objectDict = [NSMutableDictionary new];
                for (NSString *key in resource.model) {
                    [objectDict setObject:[results objectForColumnName:key] forKey:key];
                }
                [returnArray addObject:objectDict];
            }
            [results close];
        }];
        
        return [NSArray arrayWithArray:returnArray];
    } else {
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
    
    if (self.isPersisting) {
        __block BOOL saveSuccess;
        NSMutableString *sqlString = [NSMutableString new];
        for (NSString *key in newObjectStub) {
            [sqlString appendString:[NSString stringWithFormat:@"\"%@\" %@, ", key, newObjectStub[key]]];
        }
        [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length - 2, 2)];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            saveSuccess = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ VALUES(%@)", resource.name, sqlString]];
        }];
        if (saveSuccess) {
            return newObjectStub;
        } else {
            return nil;
        }
    } else {
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
    
    if (self.isPersisting) {
        
    } else {
        NSMutableDictionary *newDict = [NSMutableDictionary new];
        
        for (NSString *key in resource.model.allKeys) {
            if (![key isEqualToString:resource.primaryKey]) {
                [newDict setObject:dictionary[key] forKey:key];
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
    
    return nil;
}

- (void)deleteResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    
    if (self.isPersisting) {
        
    } else {
        
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
}


@end
