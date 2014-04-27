//
//  TGPrivateFunctions.m
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import "TGPrivateFunctions.h"
#import "TGRESTResource.h"

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

NSString * TGExtractHeaderValueParameter(NSString *value, NSString *name) {
    NSString* parameter = nil;
    NSScanner* scanner = [[NSScanner alloc] initWithString:value];
    [scanner setCaseSensitive:NO];  // Assume parameter names are case-insensitive
    NSString* string = [NSString stringWithFormat:@"%@=", name];
    if ([scanner scanUpToString:string intoString:NULL]) {
        [scanner scanString:string intoString:NULL];
        if ([scanner scanString:@"\"" intoString:NULL]) {
            [scanner scanUpToString:@"\"" intoString:&parameter];
        } else {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&parameter];
        }
    }
    return parameter;
}

NSStringEncoding TGStringEncodingFromCharset(NSString *charset) {
    NSStringEncoding encoding = kCFStringEncodingInvalidId;
    if (charset) {
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)charset));
    }
    return (encoding != kCFStringEncodingInvalidId ? encoding : NSUTF8StringEncoding);
}

NSDictionary *TGParseURLEncodedForm(NSString *form) {
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSScanner* scanner = [[NSScanner alloc] initWithString:form];
    [scanner setCharactersToBeSkipped:nil];
    while (1) {
        NSString* key = nil;
        if (![scanner scanUpToString:@"=" intoString:&key] || [scanner isAtEnd]) {
            break;
        }
        [scanner setScanLocation:([scanner scanLocation] + 1)];
        
        NSString* value = nil;
        if (![scanner scanUpToString:@"&" intoString:&value]) {
            break;
        }
        
        key = [key stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        if (key && value) {
            [parameters setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        
        if ([scanner isAtEnd]) {
            break;
        }
        [scanner setScanLocation:([scanner scanLocation] + 1)];
    }
    return parameters;
}

NSString *TGIndexRegex(TGRESTResource *resource)
{
    NSMutableString *regex = [NSMutableString new];
    
    // First append the default match
    
    [regex appendString:[NSString stringWithFormat:@"^(/%@/?$)", resource.name]];
    
    // Now add any paths from the parents
    
    for (TGRESTResource *parent in resource.parentResources) {
        [regex appendString:[NSString stringWithFormat:@"|(/%@/\\w+/%@/?$)", parent.name, resource.name]];
    }
    
    return [NSString stringWithString:regex];
}

NSString *TGShowRegex(TGRESTResource *resource)
{
    NSMutableString *regex = [NSMutableString new];
    
    // First append the default match
    
    [regex appendString:[NSString stringWithFormat:@"^(/%@/\\w+/?$)", resource.name]];
    
    // Now add any paths from the parents
    
    for (TGRESTResource *parent in resource.parentResources) {
        [regex appendString:[NSString stringWithFormat:@"|(/%@/\\w+/%@/\\w+/?$)", parent.name, resource.name]];
    }
    
    return [NSString stringWithString:regex];
}

NSString *TGCreateRegex(TGRESTResource *resource)
{
    NSMutableString *regex = [NSMutableString new];
    
    // First append the default match
    
    [regex appendString:[NSString stringWithFormat:@"^(/%@/?$)", resource.name]];
    
    // Now add any paths from the parents
    
    for (TGRESTResource *parent in resource.parentResources) {
        [regex appendString:[NSString stringWithFormat:@"|(/%@/\\w+/%@/?$)", parent.name, resource.name]];
    }
    
    return [NSString stringWithString:regex];
}

NSString *TGUpdateRegex(TGRESTResource *resource)
{
    NSMutableString *regex = [NSMutableString new];
    
    // First append the default match
    
    [regex appendString:[NSString stringWithFormat:@"^(/%@/\\w+/?$)", resource.name]];
    
    // Now add any paths from the parents
    
    for (TGRESTResource *parent in resource.parentResources) {
        [regex appendString:[NSString stringWithFormat:@"|(/%@/\\w+/%@/\\w+/?$)", parent.name, resource.name]];
    }
    
    return [NSString stringWithString:regex];
}

NSString *TGDestroyRegex(TGRESTResource *resource)
{
    NSMutableString *regex = [NSMutableString new];
    
    // First append the default match
    
    [regex appendString:[NSString stringWithFormat:@"^(/%@/\\w+/?$)", resource.name]];
    
    // Now add any paths from the parents
    
    for (TGRESTResource *parent in resource.parentResources) {
        [regex appendString:[NSString stringWithFormat:@"|(/%@/\\w+/%@/\\w+/?$)", parent.name, resource.name]];
    }
    
    return [NSString stringWithString:regex];
}
