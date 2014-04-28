//
//  TGRESTController.h
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import <Foundation/Foundation.h>
#import "TGRESTSerializer.h"

@class GCDWebServerRequest;
@class GCDWebServerResponse;
@class TGRESTResource;
@class TGRESTStore;

@protocol TGRESTController <NSObject>

@required
+ (GCDWebServerResponse *)indexWithRequest:(GCDWebServerRequest *)request
                              withResource:(TGRESTResource *)resource
                            usingDatastore:(TGRESTStore *)store;

+ (GCDWebServerResponse *)showWithRequest:(GCDWebServerRequest *)request
                             withResource:(TGRESTResource *)resource
                           usingDatastore:(TGRESTStore *)store;

+ (GCDWebServerResponse *)createWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                             usingDatastore:(TGRESTStore *)store;

+ (GCDWebServerResponse *)updateWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                             usingDatastore:(TGRESTStore *)store;

+ (GCDWebServerResponse *)destroyWithRequest:(GCDWebServerRequest *)request
                                withResource:(TGRESTResource *)resource
                              usingDatastore:(TGRESTStore *)store;
@end
