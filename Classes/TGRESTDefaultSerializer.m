//
//  TGRESTDefaultSerializer.m
//  
//
//  Created by John Tumminaro on 4/28/14.
//
//

#import "TGRESTDefaultSerializer.h"

@implementation TGRESTDefaultSerializer

+ (NSDictionary *)dataWithSingularObject:(NSDictionary *)object resource:(TGRESTResource *)resource
{
    return object;
}

+ (NSArray *)dataWithCollection:(NSArray *)collection resource:(TGRESTResource *)resource
{
    return collection;
}

@end
