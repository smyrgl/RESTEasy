//
//  TGRESTClient.h
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import "AFHTTPSessionManager.h"

@interface TGRESTClient : AFHTTPSessionManager

+ (instancetype)sharedClient;

@end
