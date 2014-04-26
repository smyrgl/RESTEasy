//
//  TGRESTPersistentServer.m
//  
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import "TGRESTPersistentServer.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerDataRequest.h>
#import "TGPrivateFunctions.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import "TGRESTServer_TGRESTServerPrivate.h"

@interface TGRESTPersistentServer ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, assign) CGFloat latencyMin;
@property (nonatomic, assign) CGFloat latencyMax;
@property (nonatomic, strong) NSMutableSet *resources;

@end

@implementation TGRESTPersistentServer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[NSString stringWithFormat:@"%@/RESTeasy.sqlite", TGApplicationDataDirectory()] flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
    }
    
    return self;
}

- (void)stopServer
{
    [self removeAllResourcesWithData:NO];
    [self.webServer stop];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TGServerDidShutdownNotification object:self];
}

#pragma mark - Resources

- (void)addResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
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

}

- (void)removeAllResourcesWithData:(BOOL)removeData
{
    [self.webServer removeAllHandlers];
    [self.resources removeAllObjects];

    if (removeData) {
        NSError *error;
        NSString *path = [self.dbQueue.path copy];
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"Error deleting sqlite store! %@", error);
        }
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:path flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
    }
}

#pragma mark - Private

- (NSDictionary *)getDataForResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error
{
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
}

- (NSArray *)getAllDataForResource:(TGRESTResource *)resource error:(NSError * __autoreleasing *)error
{
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
    
    return nil;
}

- (void)deleteResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
}

@end
