//
//  main.m
//  sandbox
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>
#import "RESTEasy.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        TGRESTResource *people = [TGRESTResource newResourceWithName:@"people" model:@{
                                                                                       @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                                                                                       @"numberOfKids": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                                                                                       @"kilometersWalked": [NSNumber numberWithInteger:TGPropertyTypeFloatingPoint],
                                                                                       @"avatar": [NSNumber numberWithInteger:TGPropertyTypeBlob]
                                                                                       }];
        
        TGRESTResource *cars = [TGRESTResource newResourceWithName:@"cars"
                                                              model:@{
                                                                      @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                                                                      @"color": [NSNumber numberWithInteger:TGPropertyTypeString]
                                                                      }
                                                            actions:TGResourceRESTActionsDELETE | TGResourceRESTActionsGET | TGResourceRESTActionsPOST | TGResourceRESTActionsPUT
                                                         primaryKey:nil
                                                    parentResources:@[people]];
        
        [[TGRESTServer sharedServer] addResource:people];
        [[TGRESTServer sharedServer] addResource:cars];
        
        [[TGRESTServer sharedServer] startServerWithOptions:@{
                                                              TGLatencyRangeMinimumOptionKey: @0.5f,
                                                              TGLatencyRangeMaximumOptionKey: @0.6f
                                                              }];
        
        __block BOOL serverRunning = YES;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:TGRESTServerDidShutdownNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note) {
                                                          serverRunning = NO;
                                                      }];
        
        while (serverRunning) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        
    }
    return 0;
}

