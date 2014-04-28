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
#import "TGRESTDefaultController.h"
#import "TGRESTDefaultSerializer.h"

NSString * const TGLatencyRangeMinimumOptionKey = @"TGLatencyRangeMinimumOptionKey";
NSString * const TGLatencyRangeMaximumOptionKey = @"TGLatencyRangeMaximumOptionKey";
NSString * const TGWebServerPortNumberOptionKey = @"TGWebServerPortNumberOptionKey";
NSString * const TGRESTServerDatastoreClassOptionKey = @"TGRESTServerDatastoreClassOptionKey";
NSString * const TGRESTServerControllerClassOptionKey = @"TGRESTServerControllerClassOptionKey";
NSString * const TGRESTServerDefaultSerializerClassOptionKey = @"TGRESTServerDefaultSerializerClassOptionKey";

NSString * const TGRESTServerDidStartNotification = @"TGRESTServerDidStartNotification";
NSString * const TGRESTServerDidShutdownNotification = @"TGRESTServerDidShutdownNotification";

static TGRESTServerLogLevel kRESTServerLogLevel = TGRESTServerLogLevelInfo;

@interface TGRESTServer () <GCDWebServerDelegate>

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, assign) CGFloat latencyMin;
@property (nonatomic, assign) CGFloat latencyMax;
@property (nonatomic, strong) NSMutableDictionary *resources;
@property (nonatomic, strong, readwrite) TGRESTStore *datastore;
@property (nonatomic, copy, readwrite) NSString *serverName;
@property (nonatomic, copy) NSDictionary *lastOptions;
@property (nonatomic, strong) NSMutableDictionary *resourceSerializers;
@property (nonatomic, strong, readwrite) Class<TGRESTSerializer> defaultSerializer;
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

+ (instancetype)serverWithName:(NSString *)name
{
    TGRESTServer *newServer = [TGRESTServer new];
    newServer.serverName = name;
    
    return newServer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.webServer = [[GCDWebServer alloc] init];
        self.resources = [NSMutableDictionary new];
        self.datastore = [TGRESTInMemoryStore new];
        self.datastore.server = self;
        self.serverName = @"";
        self.resourceSerializers = [NSMutableDictionary new];
        self.defaultSerializer = [TGRESTDefaultSerializer class];
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
    [self addResourcesWithArray:[self.resources allValues]];
    
    [options[TGWebServerPortNumberOptionKey] integerValue];
    self.latencyMin = [options[TGLatencyRangeMinimumOptionKey] floatValue];
    self.latencyMax = [options[TGLatencyRangeMaximumOptionKey] floatValue];
    
    NSMutableDictionary *serverOptionsDict = [NSMutableDictionary new];
    
    if (options[TGWebServerPortNumberOptionKey]) {
        [serverOptionsDict setObject:options[TGWebServerPortNumberOptionKey] forKey:GCDWebServerOption_Port];;
    } else {
        [serverOptionsDict setObject:@8888 forKey:GCDWebServerOption_Port];
    }
    
    if (options[TGRESTServerDefaultSerializerClassOptionKey]) {
        self.defaultSerializer = options[TGRESTServerDefaultSerializerClassOptionKey];
    }
    
    [serverOptionsDict setObject:@"RESTEasy" forKey:GCDWebServerOption_ServerName];
    [serverOptionsDict setObject:[NSString stringWithFormat:@"RESTEasy_%@", self.serverName] forKey:GCDWebServerOption_BonjourName];
    
    NSDictionary *startOptions = [NSDictionary dictionaryWithDictionary:serverOptionsDict];
    
    NSError *startError;
    BOOL started = [self.webServer startWithOptions:startOptions error:&startError];
    
    if (started) {
        NSMutableString *status = [NSMutableString stringWithString:@"\n"];
        
        [status appendFormat:@"Server started with Status: -------- \n"];
        [status appendFormat:@"Resources:           \n"];
        for (TGRESTResource *resource in self.resources.allValues) {
            [status appendFormat:@"%@                       \n", resource];
        }
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
                                       reason:[NSString stringWithFormat:@"Server failed to start with error %@", startError]
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
    return [NSSet setWithArray:self.resources.allValues];
}

- (void)addResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    if (self.isRunning) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"You cannot add resources when the server is running"
                                     userInfo:nil];
    }
    
    if (self.resources[resource.name] && ![[(TGRESTResource *)self.resources[resource.name] model] isEqual:resource.model]) {
        TGLogWarn(@"Added a resource that matches an existing resource name but has a different model.  Removing the old resource first and purging all of its data.");
        [self removeResource:self.resources[resource.name] withData:YES];
    } else if (self.resources[resource.name] && ![self.resources[resource.name] isEqual:resource]) {
        if (self.datastore.class == [TGRESTInMemoryStore class]) {
            TGLogInfo(@"Added a resource that matches an existing resource name.  Removing the old resource first and purging all of its data.");
        } else {
            TGLogInfo(@"Added a resource that matches an existing resource with the same model.  Resource will be updated non-destructively.");
        }
        [self removeResource:self.resources[resource.name] withData:NO];
    } 
    
    if (self.datastore) {
        [self.datastore addResource:resource];
    }
    [self.resources setObject:resource forKey:resource.name];
    
    if (resource.actions & TGResourceRESTActionsGET) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:TGIndexRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   return [TGRESTDefaultController indexWithRequest:request withResource:resource usingDatastore:weakSelf.datastore];
                               }];
        
        [self.webServer addHandlerForMethod:@"GET"
                                  pathRegex:TGShowRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   return [TGRESTDefaultController showWithRequest:request withResource:resource usingDatastore:weakSelf.datastore];
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsPOST) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"POST"
                                  pathRegex:TGCreateRegex(resource)
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   return [TGRESTDefaultController createWithRequest:request withResource:resource usingDatastore:weakSelf.datastore];
                               }];
        
    }
    
    if (resource.actions & TGResourceRESTActionsDELETE) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"DELETE"
                                  pathRegex:TGDestroyRegex(resource)
                               requestClass:[GCDWebServerRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   return [TGRESTDefaultController destroyWithRequest:request withResource:resource usingDatastore:weakSelf.datastore];
                               }];
    }
    
    if (resource.actions & TGResourceRESTActionsPUT) {
        __weak typeof(self) weakSelf = self;
        
        [self.webServer addHandlerForMethod:@"PUT"
                                  pathRegex:TGUpdateRegex(resource)
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                   return [TGRESTDefaultController updateWithRequest:request withResource:resource usingDatastore:weakSelf.datastore];
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
    [self.resources removeObjectForKey:resource.name];
    [self.resourceSerializers removeObjectForKey:resource.name];
}

- (void)removeAllResourcesWithData:(BOOL)removeData
{
    [self.webServer removeAllHandlers];
    
    NSMutableArray *operations = [NSMutableArray new];
    
    __weak typeof(self) weakSelf = self;

    for (TGRESTResource *resource in self.resources.allValues) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [weakSelf removeResource:resource withData:removeData];
        }];
        [operations addObject:operation];
    }
    
    for (NSBlockOperation *op in operations) {
        [op start];
    }
}

- (NSDictionary *)serializers
{
    return [NSDictionary dictionaryWithDictionary:self.resourceSerializers];
}

- (void)setSerializerClass:(Class)class forResource:(TGRESTResource *)resource
{
    [self.resourceSerializers setObject:class forKey:resource.name];
}

- (void)removeCustomSerializerForResource:(TGRESTResource *)resource
{
    [self.resourceSerializers removeObjectForKey:resource.name];
}

- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    if (!self.resources[resource.name]) {
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

@end
