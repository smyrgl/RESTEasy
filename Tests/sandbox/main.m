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
        
        TGRESTResource *person = [TGRESTResource newResourceWithName:@"people"
                                                                 model:@{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]}];
        TGRESTResource *email = [TGRESTResource newResourceWithName:@"emails"
                                                              model:@{@"address": [NSNumber numberWithInteger:TGPropertyTypeString]}
                                                            actions:TGResourceRESTActionsDELETE | TGResourceRESTActionsGET | TGResourceRESTActionsPOST | TGResourceRESTActionsPUT
                                                         primaryKey:nil
                                                    parentResources:@[person]];
        
        [[TGRESTServer sharedServer] addResource:person];
        [[TGRESTServer sharedServer] addResource:email];

        [[TGRESTServer sharedServer] startServerWithOptions:nil];
        
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

