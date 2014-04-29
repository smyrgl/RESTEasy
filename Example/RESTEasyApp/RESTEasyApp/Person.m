//
//  Person.m
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "Person.h"

@implementation Person

+ (NSDictionary *)foundryBuildSpecs
{
    return @{
             @"name": [NSNumber numberWithInteger:FoundryPropertyTypeFullName],
             @"email": [NSNumber numberWithInteger:FoundryPropertyTypeEmail]
             };
}

@end
