//
//  TGRESTEasyAPI.h
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface TGRESTEasyAPI : AFHTTPSessionManager

+ (instancetype)sharedClient;

@end
