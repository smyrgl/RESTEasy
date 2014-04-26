//
//  TGRESTServer_TGRESTServerPrivate.h
//  
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import "TGRESTServer.h"

extern NSString * const TGRESTServerErrorDomain;
extern NSUInteger const TGRESTServerObjectDeletedErrorCode;
extern NSUInteger const TGRESTServerObjectNotFoundErrorCode;
extern NSUInteger const TGRESTServerUnknownErrorCode;
extern NSUInteger const TGRESTServerBadRequestErrorCode;

@interface TGRESTServer ()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, assign) CGFloat latencyMin;
@property (nonatomic, assign) CGFloat latencyMax;
@property (nonatomic, strong) NSMutableSet *resources;
@property (atomic, strong) NSMutableDictionary *inMemoryDatastore;

+ (GCDWebServerResponse *)errorResponseBuilderWithError:(NSError *)error;
- (NSDictionary *)getDataForResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error;
- (NSArray *)getAllDataForResource:(TGRESTResource *)resource error:(NSError * __autoreleasing *)error;
- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource withDictionary:(NSDictionary *)dictionary error:(NSError * __autoreleasing *)error;
- (NSDictionary *)modifyResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk withDictionary:(NSDictionary *)dictionary error:(NSError * __autoreleasing *)error;
- (void)deleteResource:(TGRESTResource *)resource withPrimaryKey:(NSString *)pk error:(NSError * __autoreleasing *)error;

@end
