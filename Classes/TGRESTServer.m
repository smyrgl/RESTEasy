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

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.webServer = [[GCDWebServer alloc] init];
        self.webServer.delegate = self;
        self.resources = [NSMutableSet new];
        self.datastore = [TGRESTInMemoryStore new];
        self.datastore.server = self;
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

#pragma mark - Server control

- (void)startServerWithOptions:(NSDictionary *)options
{
    NSUInteger serverPort;
    
    if (options[TGWebServerPortNumberOptionKey]) {
        serverPort = [options[TGWebServerPortNumberOptionKey] integerValue];
    } else {
        serverPort = 8888;
    }
    
    if (options[TGRESTServerDatastoreClassOptionKey]) {
        Class aClass = options[TGRESTServerDatastoreClassOptionKey];
        self.datastore = [aClass new];
    } else if (self.datastore.class != [TGRESTInMemoryStore class]) {
        self.datastore = [TGRESTInMemoryStore new];
    }
    
    self.datastore.server = self;
    TGLogInfo(@"Starting server with datastore %@", self.datastore.name);
    
    [options[TGWebServerPortNumberOptionKey] integerValue];
    self.latencyMin = [options[TGLatencyRangeMinimumOptionKey] floatValue];
    self.latencyMax = [options[TGLatencyRangeMaximumOptionKey] floatValue];
    [self.webServer startWithPort:serverPort bonjourName:nil];
}

- (void)stopServer
{
    [self.webServer stop];
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
    
    [self.datastore addResource:resource];
    [self.resources addObject:resource];
    
    if (resource.actions & TGResourceRESTActionsGET) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:TGIndexRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   if (request.URL.pathComponents.count > 2) {
                                       NSString *parentName = request.URL.pathComponents[1];
                                       NSString *parentID = request.URL.pathComponents[2];
                                       NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", parentName];
                                       TGRESTResource *parent = [[resource.parentResources filteredArrayUsingPredicate:predicate] firstObject];
                                       NSError *error;
                                       NSArray *dataWithParent = [strongSelf.datastore getDataForObjectsOfResource:resource
                                                                                                        withParent:parent
                                                                                                  parentPrimaryKey:parentID
                                                                                                             error:&error];
                                       
                                       if (error) {
                                           return [TGRESTServer errorResponseBuilderWithError:error];
                                       }
                                       return [GCDWebServerDataResponse responseWithJSONObject:dataWithParent];
                                   }
                                   NSError *error;
                                   NSArray *allData = [strongSelf.datastore getAllObjectsForResource:resource error:&error];
                                   if (error) {
                                       return [TGRESTServer errorResponseBuilderWithError:error];
                                   }
                                   return [GCDWebServerDataResponse responseWithJSONObject:allData];
                               }];
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:TGShowRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   NSError *error;
                                   NSDictionary *resourceResponse = [strongSelf.datastore getDataForObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
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
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
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
                                   
                                   NSDictionary *newObject = [strongSelf.datastore createNewObjectForResource:resource withProperties:sanitizedBody error:&error];
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
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   NSString *lastPathComponent = request.URL.lastPathComponent;
                                   if ([lastPathComponent isEqualToString:resource.name]) {
                                       return [GCDWebServerResponse responseWithStatusCode:403];
                                   }
                                   NSError *error;
                                   [strongSelf.datastore deleteObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
                                   
                                   if (error) {
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
                                           TGLogError(@"Failed to deserialize JSON payload %@", jsonError);
                                           return [GCDWebServerResponse responseWithStatusCode:400];
                                       }
                                   } else if ([dataRequest.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
                                       NSString* charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
                                       NSString* formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
                                       body = TGParseURLEncodedForm(formURLString);
                                   }
                                   
                                   NSDictionary *sanitizedBody = [TGRESTServer sanitizedPropertiesForResource:resource withProperties:body];
                                   if (sanitizedBody.allKeys.count == 0) {
                                       TGLogWarn(@"Request contains no keys matching valid parameters for resource %@ %@", resource.name, body);
                                       return [GCDWebServerResponse responseWithStatusCode:400];
                                   }
                                   
                                   NSError *error;
                                   NSDictionary *resourceResponse = [strongSelf.datastore modifyObjectOfResource:resource withPrimaryKey:lastPathComponent withProperties:sanitizedBody error:&error];
                                   
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

#pragma mark - GCDWebServer delegate

- (void)webServerDidStart:(GCDWebServer *)server
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TGRESTServerDidStartNotification object:self];
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
