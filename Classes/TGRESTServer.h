//
//  TGRESTServer.h
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTStore;
@class TGRESTResource;

extern NSString * const TGLatencyRangeMinimumOptionKey;
extern NSString * const TGLatencyRangeMaximumOptionKey;
extern NSString * const TGWebServerPortNumberOptionKey;
extern NSString * const TGRESTServerDatastoreClassOptionKey;
extern NSString * const TGRESTServerControllerClassOptionKey;
extern NSString * const TGRESTServerSerializerClassOptionKey;

typedef NS_OPTIONS(NSUInteger, TGRESTServerLogLevel) {
    TGRESTServerLogLevelOff       = 0,
    TGRESTServerLogLevelFatal     = 1 << 0,
    TGRESTServerLogLevelError     = 1 << 1,
    TGRESTServerLogLevelWarn      = 1 << 2,
    TGRESTServerLogLevelInfo      = 1 << 3,
    TGRESTServerLogLevelVerbose   = 1 << 4
};

/**
 *  TGRESTServer is the primary class for running and managing your RESTful server using RESTEasy.  It is designed to be as simple as possible to use, while providing reasonable options for configuration relevant to its intented use cases as a prototyping and testing server.  
 */

@interface TGRESTServer : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, copy, readonly) NSString *serverName;
@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, copy, readonly) NSString *serverBonjourName;
@property (nonatomic, copy, readonly) NSURL *serverBonjourURL;
@property (nonatomic, strong, readonly) TGRESTStore *datastore;

+ (instancetype)sharedServer;

+ (TGRESTServerLogLevel)logLevel;
+ (void)setLogLevel:(TGRESTServerLogLevel)level;

- (void)startServerWithOptions:(NSDictionary *)options;
- (void)stopServer;

- (NSSet *)currentResources;
- (void)addResource:(TGRESTResource *)resource;
- (void)addResourcesWithArray:(NSArray *)resources;
- (void)removeResource:(TGRESTResource *)resource withData:(BOOL)removeData;
- (void)removeAllResourcesWithData:(BOOL)removeData;
- (NSDictionary *)serializers;
- (void)setSerializerClass:(Class)class forResource:(TGRESTResource *)resource;
- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource;
- (NSArray *)allObjectsForResource:(TGRESTResource *)resource;
- (void)addData:(NSArray *)data forResource:(TGRESTResource *)resource;

@end

extern NSString * const TGRESTServerDidStartNotification;
extern NSString * const TGRESTServerDidShutdownNotification;
