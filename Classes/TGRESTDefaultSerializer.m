//
//  TGRESTDefaultSerializer.m
//  
//
//  Created by John Tumminaro on 4/28/14.
//
//

#import "TGRESTDefaultSerializer.h"

@implementation TGRESTDefaultSerializer

+ (id)dataWithSingularObject:(NSDictionary *)object resource:(TGRESTResource *)resource
{
    NSParameterAssert(object);
    NSParameterAssert(resource);
    
    return object;
}

+ (id)dataWithCollection:(NSArray *)collection resource:(TGRESTResource *)resource
{
    NSParameterAssert(collection);
    NSParameterAssert(resource);
    
    return collection;
}

+ (NSDictionary *)requestParametersWithBody:(NSDictionary *)body resource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    return body;
}

@end
