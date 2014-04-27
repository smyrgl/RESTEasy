//
//  TGRESTSqliteStore.m
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import "TGRESTSqliteStore.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import "TGPrivateFunctions.h"
#import "TGRESTResource.h"
#import "TGRESTEasyLogging.h"

@interface TGRESTSqliteStore ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation TGRESTSqliteStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[NSString stringWithFormat:@"%@/RESTeasy.sqlite", TGApplicationDataDirectory()] flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_DBCONFIG_ENABLE_FKEY];
    }
    
    return self;
}

- (NSUInteger)countOfObjectsForResource:(TGRESTResource *)resource
{
    __block NSUInteger returnCount;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        returnCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(%@) FROM %@", resource.primaryKey, resource.name]];
    }];
    
    return returnCount;
}

- (NSDictionary *)getDataForObjectOfResource:(TGRESTResource *)resource
                              withPrimaryKey:(NSString *)primaryKey
                                       error:(NSError * __autoreleasing *)error
{
    TGLogInfo(@"Getting data for resource %@ with primary key %@ using sqlite store", resource.name, resource.primaryKey);
    __block NSMutableDictionary *returnDictionary = [NSMutableDictionary new];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %@", resource.name, resource.primaryKey, primaryKey]];
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

- (NSArray *)getAllObjectsForResource:(TGRESTResource *)resource
                                error:(NSError * __autoreleasing *)error
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

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource
                              withProperties:(NSDictionary *)properties
                                       error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    NSParameterAssert(properties);
    
    __block BOOL saveSuccess;
    NSMutableString *keyString = [NSMutableString new];
    NSMutableString *valueString = [NSMutableString new];
    for (NSString *key in properties) {
        [keyString appendString:[NSString stringWithFormat:@"'%@', ", key]];
        [valueString appendString:[NSString stringWithFormat:@"'%@', ", properties[key]]];
    }
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 2, 2)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 2, 2)];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        saveSuccess = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES(%@)", resource.name, keyString, valueString]];
    }];
    if (saveSuccess) {
        return properties;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:TGRESTStoreErrorDomain code:TGRESTStoreUnknownErrorCode userInfo:nil];
        }
        return nil;
    }
}

- (NSDictionary *)modifyObjectOfResource:(TGRESTResource *)resource
                          withPrimaryKey:(NSString *)primaryKey
                          withProperties:(NSDictionary *)properties
                                   error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)deleteObjectOfResource:(TGRESTResource *)resource
                withPrimaryKey:(NSString *)primaryKey
                         error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(resource);
    NSParameterAssert(primaryKey);
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in your custom TGRESTStore", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)addResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    NSDictionary *newModel = [resource valueForKey:@"sqliteModel"];
    __block BOOL resetTable = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *tableInfo = [db getTableSchema:resource.name];
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
            if ([key isEqualToString:resource.primaryKey]) {
                [columnString appendString:[NSString stringWithFormat:@"\"%@\" %@ PRIMARY KEY UNIQUE, ", key, newModel[key]]];
            } else if (resource.foreignKeys[key]) {
                TGRESTResource *parent = resource.foreignKeys[key];
                [columnString appendString:[NSString stringWithFormat:@"\"%@\" %@, FOREIGN KEY(%@) REFERENCES %@(%@), ", key, newModel[key], key, parent.name, parent.primaryKey]];
            } else {
                [columnString appendString:[NSString stringWithFormat:@"\"%@\" %@, ", key, newModel[key]]];
            }
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

- (void)dropResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", resource.name]]) {
            TGLogError(@"ERROR: Can't drop table for resource %@ %@", resource.name, [db lastError]);
        }
    }];
}

+ (NSString *)description
{
    return @"InMemoryStore";
}


@end
