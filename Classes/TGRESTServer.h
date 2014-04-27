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

typedef NS_OPTIONS(NSUInteger, TGRESTServerLogLevel) {
    TGRESTServerLogLevelOff       = 0,
    TGRESTServerLogLevelFatal     = 1 << 0,
    TGRESTServerLogLevelError     = 1 << 1,
    TGRESTServerLogLevelWarn      = 1 << 2,
    TGRESTServerLogLevelInfo      = 1 << 3,
    TGRESTServerLogLevelVerbose   = 1 << 4
};

@interface TGRESTServer : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, strong, readonly) NSURL *serverURL;
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
- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource;
- (NSArray *)allObjectsForResource:(TGRESTResource *)resource;
- (void)addData:(NSArray *)data forResource:(TGRESTResource *)resource;

@end

extern NSString * const TGRESTServerDidStartNotification;
extern NSString * const TGRESTServerDidShutdownNotification;

