//
//  TGRESTServer.h
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTResource;

extern NSString * const TGLatencyRangeMinimumOptionKey;
extern NSString * const TGLatencyRangeMaximumOptionKey;
extern NSString * const TGPersistenceNameOptionKey;
extern NSString * const TGWebServerPortNumberOptionKey;

@interface TGRESTServer : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign, readonly, getter = isPersisting) BOOL persisting;

+ (instancetype)sharedServer;

- (void)startServerWithOptions:(NSDictionary *)options;
- (void)stopServer;

- (NSSet *)currentResources;
- (void)addResource:(TGRESTResource *)resource;
- (void)removeResource:(TGRESTResource *)resource;

@end

extern NSString * const TGServerDidStartNotification;
extern NSString * const TGServerDidShutdownNotification;

