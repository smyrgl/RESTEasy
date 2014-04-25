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
                                           return [GCDWebServerDataResponse responseWithJSONObject:[strongSelf getAllDataForResource:resource]];
                                       }
                                       NSDictionary *resourceResponse = [strongSelf getDataForResource:resource withPrimaryKey:lastPathComponent];
                                       if (resourceResponse) {
                                           return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
                                       } else {
                                           return [GCDWebServerResponse responseWithStatusCode:404];
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
                                       NSDictionary *newObject = [strongSelf createNewObjectForResource:resource withDictionary:body];
                                       if (newObject) {
                                           return [GCDWebServerDataResponse responseWithJSONObject:newObject];
                                       } else {
                                           return [GCDWebServerResponse responseWithStatusCode:500];
                                       }
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
                                       BOOL isDeleted = [strongSelf deleteResource:resource withPrimaryKey:lastPathComponent];
                                       if (isDeleted) {
                                           return [GCDWebServerResponse responseWithStatusCode:204];
                                       } else {
                                           return [GCDWebServerResponse responseWithStatusCode:404];
                                       }
                                   }];
        }
    }
    
    if (resource.actions & TGResourceRESTActionsPUT) {
        __weak typeof(self) weakSelf = self;
        
        for (NSString *route in resource.routes) {
            [self.webServer addHandlerForMethod:@"PUT"
                                      pathRegex:[NSString stringWithFormat:@"^/(%@)", route]
                                   requestClass:[GCDWebServerRequest class]
                                   processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       NSString *lastPathComponent = request.URL.lastPathComponent;
                                       if ([lastPathComponent isEqualToString:resource.name]) {
                                           return [GCDWebServerResponse responseWithStatusCode:403];
                                       }
                                       NSDictionary *resourceResponse = [strongSelf modifyResource:resource withPrimaryKey:lastPathComponent withDictionary:request.query];
                                       if (resourceResponse) {
                                           return [GCDWebServerDataResponse responseWithJSONObject:[strongSelf getDataForResource:resource withPrimaryKey:lastPathComponent]];
                                       } else {
                                           return [GCDWebServerResponse responseWithStatusCode:404];
                                       }
                                   }];
        }
    }
        
    [self.resources addObject:resource];
}

- (void)removeResource:(TGRESTResource *)resource
{
    
}

#pragma mark - Private

- (NSDictionary *)getDataForResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk
{
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
        if (resource.primaryKeyType == TGPropertyTypeInteger) {
            return objects[[NSNumber numberWithInteger:[pk integerValue]]];
        } else {
            return objects[pk];
        }
    }
    
    return nil;
}

- (NSArray *)getAllDataForResource:(TGRESTResource *)resource
{
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
        return [[objects allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:resource.primaryKey ascending:YES]]];
    }
}

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource withDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert(resource);
    NSParameterAssert(dictionary);
    
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

- (NSDictionary *)modifyResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk withDictionary:(NSDictionary *)dictionary
{
    return @{};
}

- (BOOL)deleteResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk
{
    return YES;
}


@end
