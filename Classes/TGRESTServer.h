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
extern NSString * const TGWebServerPortNumberOptionKey;

@interface TGRESTServer : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;

+ (instancetype)sharedServer;

- (void)startServerWithOptions:(NSDictionary *)options;
- (void)stopServer;

- (NSSet *)currentResources;
- (void)addResource:(TGRESTResource *)resource;
- (void)removeResource:(TGRESTResource *)resource withData:(BOOL)removeData;
- (void)removeAllResourcesWithData:(BOOL)removeData;

- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource;
- (NSArray *)allObjectsForResource:(TGRESTResource *)resource;
- (void)addData:(NSArray *)data forResource:(TGRESTResource *)resource;

@end

extern NSString * const TGServerDidStartNotification;
extern NSString * const TGServerDidShutdownNotification;

