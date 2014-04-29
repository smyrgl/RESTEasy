//
//  TGRESTEasyAPI.m
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "TGRESTEasyAPI.h"

@implementation TGRESTEasyAPI

+ (instancetype)sharedClient
{
    static dispatch_once_t onceQueue;
    static TGRESTEasyAPI *sharedClient = nil;
    
    dispatch_once(&onceQueue, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init
{
    self = [super initWithBaseURL:[[TGRESTServer sharedServer] serverURL]];
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    return self;
}

@end
