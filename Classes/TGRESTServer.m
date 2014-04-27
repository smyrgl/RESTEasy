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
#import <GCDWebServer/GCDWebServerURLEncodedFormRequest.h>
#import "TGPrivateFunctions.h"
#import "TGRESTStore.h"
#import "TGRESTInMemoryStore.h"
#import "TGRESTEasyLogging.h"

NSString * const TGLatencyRangeMinimumOptionKey = @"TGLatencyRangeMinimumOptionKey";
NSString * const TGLatencyRangeMaximumOptionKey = @"TGLatencyRangeMaximumOptionKey";
NSString * const TGWebServerPortNumberOptionKey = @"TGWebServerPortNumberOptionKey";
NSString * const TGRESTServerDatastoreClassOptionKey = @"TGRESTServerDatastoreClassOptionKey";

NSString * const TGRESTServerDidStartNotification = @"TGRESTServerDidStartNotification";
NSString * const TGRESTServerDidShutdownNotification = @"TGRESTServerDidShutdownNotification";

static TGRESTServerLogLevel kRESTServerLogLevel = TGRESTServerLogLevelInfo;

@interface TGRESTServer () <GCDWebServerDelegate>

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, assign) CGFloat latencyMin;
@property (nonatomic, assign) CGFloat latencyMax;
@property (nonatomic, strong) NSMutableSet *resources;
@property (nonatomic, strong, readwrite) TGRESTStore *datastore;
@property (nonatomic, copy, readwrite) NSString *serverName;
@property (nonatomic, copy) NSDictionary *lastOptions;

@end

@implementation TGRESTServer

#pragma mark - Initialization

+ (instancetype)sharedServer
{
    static dispatch_once_t onceQueue;
    static TGRESTServer *sharedServer = nil;
    
    dispatch_once(&onceQueue, ^{
        sharedServer = [[self alloc] init];
        sharedServer.serverName = @"shared";
    });
    return sharedServer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.webServer = [[GCDWebServer alloc] init];
        self.resources = [NSMutableSet new];
        self.datastore = [TGRESTInMemoryStore new];
        self.datastore.server = self;
        self.serverName = @"";
    }
    
    return self;
}

#pragma mark - Class logging methods

+ (TGRESTServerLogLevel)logLevel
{
    return kRESTServerLogLevel;
}

+ (void)setLogLevel:(TGRESTServerLogLevel)level
{
    kRESTServerLogLevel = level;
}

#pragma mark - Override getters

- (BOOL)isRunning
{
    return self.webServer.isRunning;
}

- (NSURL *)serverURL
{
    return self.webServer.serverURL;
}

- (NSString *)serverBonjourName
{
    return self.webServer.bonjourName;
}

- (NSURL *)serverBonjourURL
{
    return self.webServer.bonjourServerURL;
}

#pragma mark - Server control

- (void)startServerWithOptions:(NSDictionary *)options
{
    if (self.isRunning) {
        TGLogWarn(@"Server is already running, performing server restart");
        [self.webServer stop];
    }
    
    self.lastOptions = options;
    
    if (options[TGRESTServerDatastoreClassOptionKey]) {
        Class aClass = options[TGRESTServerDatastoreClassOptionKey];
        self.datastore = [aClass new];
    } else {
        self.datastore = [TGRESTInMemoryStore new];
    }
    
    self.datastore.server = self;
    [self addResourcesWithArray:[self.resources allObjects]];
    
    [options[TGWebServerPortNumberOptionKey] integerValue];
    self.latencyMin = [options[TGLatencyRangeMinimumOptionKey] floatValue];
    self.latencyMax = [options[TGLatencyRangeMaximumOptionKey] floatValue];
    
    NSMutableDictionary *serverOptionsDict = [NSMutableDictionary new];
    
    if (options[TGWebServerPortNumberOptionKey]) {
        [serverOptionsDict setObject:options[TGWebServerPortNumberOptionKey] forKey:GCDWebServerOption_Port];;
    } else {
        [serverOptionsDict setObject:@8888 forKey:GCDWebServerOption_Port];
    }
    
    [serverOptionsDict setObject:@"RESTEasy" forKey:GCDWebServerOption_ServerName];
    [serverOptionsDict setObject:[NSString stringWithFormat:@"RESTEasy_%@", self.serverName] forKey:GCDWebServerOption_BonjourName];
    
    __block BOOL started = NO;
    __block BOOL retrying = NO;
    int retryCount = 0;
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *startOptions = [NSDictionary dictionaryWithDictionary:serverOptionsDict];
    
    while (!started && retryCount < 5) {
        if (retryCount == 0) {
            started = [self.webServer startWithOptions:startOptions];
            if (!started) {
                retryCount++;
            }
        } else if (!retrying) {
            TGLogWarn(@"Failed to start server, retrying...");
            retrying = YES;
            retryCount++;
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 200ull * NSEC_PER_MSEC);
                dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    TGLogInfo(@"Retrying server start...");
                    started = [weakSelf.webServer startWithOptions:startOptions];
                    retrying = NO;
                });
            });
            [NSThread sleepForTimeInterval:0.2f];
        }
    }
    
    
    if (started) {
        NSMutableString *status = [NSMutableString stringWithString:@"\n"];
        
        [status appendFormat:@"Server started with Status: -------- \n"];
        [status appendFormat:@"Resources:           %@\n", self.resources];
        [status appendFormat:@"Server URL:          %@\n", self.serverURL];
        [status appendFormat:@"Server Port:         %lu\n", (unsigned long)self.webServer.port];
        [status appendFormat:@"Server Latency Min:  %.2f sec\n", self.latencyMin];
        [status appendFormat:@"Server Latency Max:  %.2f sec\n", self.latencyMax];
        [status appendFormat:@"Store:               %@\n", self.datastore];
        [status appendFormat:@"------------------------------------ \n"];
        
        TGLogInfo(@"%@", status);
        [[NSNotificationCenter defaultCenter] postNotificationName:TGRESTServerDidStartNotification object:self];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Server failed to start with retry count %d", retryCount]
                                     userInfo:nil];
    }
}

- (void)stopServer
{
    [self.webServer stop];
    [self.webServer removeAllHandlers];
    self.datastore = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:TGRESTServerDidShutdownNotification object:self];
}

#pragma mark - Resources

- (NSSet *)currentResources
{
    return [NSSet setWithSet:self.resources];
}

- (void)addResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    if (self.isRunning) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"You cannot add resources when the server is running"
                                     userInfo:nil];
    }
    
    if (self.datastore) {
        [self.datastore addResource:resource];
    }
    [self.resources addObject:resource];
    
    if (resource.actions & TGResourceRESTActionsGET) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:TGIndexRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   if (request.URL.pathComponents.count > 2) {
                                       NSString *parentName = request.URL.pathComponents[1];
                                       NSString *parentID = request.URL.pathComponents[2];
                                       NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", parentName];
                                       TGRESTResource *parent = [[resource.parentResources filteredArrayUsingPredicate:predicate] firstObject];
                                       NSError *error;
                                       NSArray *dataWithParent = [weakSelf.datastore getDataForObjectsOfResource:resource
                                                                                                      withParent:parent
                                                                                                parentPrimaryKey:parentID
                                                                                                           error:&error];
                                       
                                       if (error) {
                                           return [TGRESTServer errorResponseBuilderWithError:error];
                                       }
                                       return [GCDWebServerDataResponse responseWithJSONObject:dataWithParent];
                                   }
                                   NSError *error;
                                   NSArray *allData = [weakSelf.datastore getAllObjectsForResource:resource error:&error];
                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:allData];
                               }];
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:TGShowRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   NSError *error;
                                   NSDictionary *resourceResponse = [weakSelf.datastore getDataForObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsPOST) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"POST"
                                  pathRegex:TGCreateRegex(resource)
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
                                   NSDictionary *body;
                                   if ([request.contentType hasPrefix:@"application/json"]) {
                                       NSError *jsonError;
                                       body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:NSJSONReadingAllowFragments error:&jsonError];
                                       if (jsonError) {
                                           return [GCDWebServerResponse responseWithStatusCode:400];
                                       }
                                   } else if ([request.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
                                       NSString* charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
                                       NSString* formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
                                       body = TGParseURLEncodedForm(formURLString);
                                   }
                                   NSError *error;
                                   NSDictionary *sanitizedBody = [TGRESTServer sanitizedPropertiesForResource:resource withProperties:body];
                                   if (sanitizedBody.allKeys.count == 0) {
                                       return [GCDWebServerResponse responseWithStatusCode:400];
                                   }
                                   
                                   NSDictionary *newObject = [weakSelf.datastore createNewObjectForResource:resource withProperties:sanitizedBody error:&error];
                                   
                                   body = nil;
                                   dataRequest = nil;
                                   sanitizedBody = nil;

                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:newObject];
                               }];
        
    }
    
    if (resource.actions & TGResourceRESTActionsDELETE) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"DELETE"
                                  pathRegex:TGDestroyRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   if ([lastPathComponent isEqualToString:resource.name]) {
                                       return [GCDWebServerResponse responseWithStatusCode:403];
                                   }
                                   NSError *error;
                                   BOOL success = [weakSelf.datastore deleteObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
                                   
                                   if (!success) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerResponse responseWithStatusCode:204];
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsPUT) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"PUT"
                                  pathRegex:TGUpdateRegex(resource)
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
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
                                           TGLogError(@"Failed to deserialize JSON payload %@", jsonError);
                                           return [GCDWebServerResponse responseWithStatusCode:400];
                                       }
                                   } else if ([dataRequest.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
                                       NSString *charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
                                       NSString *formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
                                       body = TGParseURLEncodedForm(formURLString);
                                   }
                                   
                                   NSDictionary *sanitizedBody = [TGRESTServer sanitizedPropertiesForResource:resource withProperties:body];
                                   if (sanitizedBody.allKeys.count == 0) {
                                       TGLogWarn(@"Request contains no keys matching valid parameters for resource %@ %@", resource.name, body);
                                       return [GCDWebServerResponse responseWithStatusCode:400];
                                   }
                                   
                                   NSError *error;
                                   NSDictionary *resourceResponse = [weakSelf.datastore modifyObjectOfResource:resource withPrimaryKey:lastPathComponent withProperties:sanitizedBody error:&error];
                                   
                                   body = nil;
                                   dataRequest = nil;
                                   sanitizedBody = nil;
                                   
                                   if (error) {
                                       TGLogError(@"Error modifying object of resource %@ with primary key %@", resource.name, lastPathComponent);
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
                               }];
    }
}

- (void)addResourcesWithArray:(NSArray *)resources
{
    for (TGRESTResource *newResource in resources) {
        [self addResource:newResource];
    }
}

- (void)removeResource:(TGRESTResource *)resource withData:(BOOL)removeData
{
    if (removeData) {
        [self.datastore dropResource:resource];
    }
    
    [self.resources removeObject:resource];
}

- (void)removeAllResourcesWithData:(BOOL)removeData
{
    [self.webServer removeAllHandlers];
    
    NSMutableArray *operations = [NSMutableArray new];
    
    __weak typeof(self) weakSelf = self;

    for (TGRESTResource *resource in self.resources) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [weakSelf removeResource:resource withData:removeData];
        }];
        [operations addObject:operation];
    }
    
    for (NSBlockOperation *op in operations) {
        [op start];
    }
}

- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    if (![self.resources containsObject:resource]) {
        TGLogWarn(@"The resource %@ has not been added to the server", resource.name);
        return 0;
    } else {
        return [self.datastore countOfObjectsForResource:resource];
    }
}

- (NSArray *)allObjectsForResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    if (![self.currentResources containsObject:resource]) {
        TGLogWarn(@"The resource %@ has not been added to the server", resource.name);
        return @[];
    }
    
    NSError *error;
    NSArray *allObjects = [self.datastore getAllObjectsForResource:resource error:&error];
    if (error) {
        TGLogError(@"Error getting objects %@", error);
        return @[];
    }
    
    return allObjects;
}

- (void)addData:(NSArray *)data forResource:(TGRESTResource *)resource
{
    for (NSDictionary *objectDictionary in data) {
        NSMutableDictionary *newObjectStub = [NSMutableDictionary new];
        
        for (NSString *key in resource.model.allKeys) {
            if (objectDictionary[key]) {
                [newObjectStub setObject:objectDictionary[key] forKey:key];
            }
        }
        
        if (newObjectStub.allKeys.count > 0) {
            NSError *error;
            [self.datastore createNewObjectForResource:resource
                                        withProperties:[NSDictionary dictionaryWithDictionary:newObjectStub]
                                                 error:&error];
            if (error) {
                TGLogError(@"Can't create object with properties %@ %@", newObjectStub, error);
            }
        } else {
            TGLogWarn(@"No matching keys for object %@", objectDictionary);
        }
    }
}

#pragma mark - Private

+ (GCDWebServerResponse *)errorResponseBuilderWithError:(NSError *)error
{
    NSParameterAssert(error);
    
    if (error.code == TGRESTStoreObjectAlreadyDeletedErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:410];
    } else if (error.code == TGRESTStoreObjectNotFoundErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:404];
    } else if (error.code == TGRESTStoreBadRequestErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:400];
    } else {
        return [GCDWebServerResponse responseWithStatusCode:500];
    }
}

+ (NSDictionary *)sanitizedPropertiesForResource:(TGRESTResource *)resource withProperties:(NSDictionary *)properties
{
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    for (NSString *key in resource.model.allKeys) {
        if (properties[key]) {
            [returnDict setObject:properties[key] forKey:key];
        }
    }
    return [NSDictionary dictionaryWithDictionary:returnDict];
}

@end
