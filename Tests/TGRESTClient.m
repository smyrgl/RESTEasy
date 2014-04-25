//
//  TGRESTClient.m
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import "TGRESTClient.h"

@implementation TGRESTClient

+ (instancetype)sharedClient
{
    static dispatch_once_t onceQueue;
    static TGRESTClient *sharedClient = nil;
    
    dispatch_once(&onceQueue, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init
{
    self = [super initWithBaseURL:[NSURL URLWithString:@"http://localhost:8888/"]];
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    return self;
}

@end
