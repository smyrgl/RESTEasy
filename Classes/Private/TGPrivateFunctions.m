//
//  TGPrivateFunctions.m
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import "TGPrivateFunctions.h"

NSString *TGApplicationDataDirectory(void)
{
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
#else
    NSFileManager *sharedFM = [NSFileManager defaultManager];
    
    NSArray *possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL *appSupportDir = nil;
    NSURL *appDirectory = nil;
    
    if ([possibleURLs count] >= 1) {
        appSupportDir = [possibleURLs objectAtIndex:0];
    }
    
    if (appSupportDir) {
        appDirectory = [appSupportDir URLByAppendingPathComponent:TGExecutableName()];
        return [appDirectory path];
    }
    
    return nil;
#endif
}

NSString * TGExecutableName(void)
{
    NSString *executableName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
    if (nil == executableName) {
        executableName = @"RESTEasy";
    }
    
    return executableName;
}