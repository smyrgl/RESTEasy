//
//  TGAppDelegate.m
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/27/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "TGAppDelegate.h"
#import "RESTEasy.h"

@implementation TGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    TGRESTResource *people = [TGRESTResource newResourceWithName:@"people"
                                                           model:@{
                                                                   @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                                                                   @"email": [NSNumber numberWithInteger:TGPropertyTypeString]
                                                                   }];
    
    TGRESTResource *pets = [TGRESTResource newResourceWithName:@"pets"
                                                         model:@{
                                                                 @"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                                                                 @"breed": [NSNumber numberWithInteger:TGPropertyTypeString]
                                                                 }
                                                       actions:TGResourceRESTActionsDELETE | TGResourceRESTActionsGET | TGResourceRESTActionsPOST | TGResourceRESTActionsPUT
                                                    primaryKey:nil
                                               parentResources:@[people]];
    
    [[TGRESTServer sharedServer] addResource:people];
    [[TGRESTServer sharedServer] addResource:pets];
    
    NSDictionary *options = @{
                              TGRESTServerDatastoreClassOptionKey: [TGRESTInMemoryStore class]
                              };
    
    [[TGRESTServer sharedServer] startServerWithOptions:options];
    
    NSArray *peopleArray = [Person foundryAttributesNumber:10];
    [[TGRESTServer sharedServer] addData:peopleArray forResource:people];
    NSArray *createdPeopleArray = [[TGRESTServer sharedServer] allObjectsForResource:people];
    
    NSMutableArray *petsArray = [NSMutableArray new];
    
    for (NSDictionary *personDict in createdPeopleArray) {
        NSArray *personPetsArray = [Pet foundryAttributesNumber:5];
        for (NSDictionary *pet in personPetsArray) {
            NSMutableDictionary *petMutable = [pet mutableCopy];
            [petMutable setObject:personDict[people.primaryKey] forKey:pets.foreignKeys[people.name]];
            [petsArray addObject:petMutable];
        }
    }
    
    [[TGRESTServer sharedServer] addData:[NSArray arrayWithArray:petsArray] forResource:pets];
    
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
