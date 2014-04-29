//
//  Pet.m
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "Pet.h"

@implementation Pet

+ (NSDictionary *)foundryBuildSpecs
{
    return @{
             @"name": [NSNumber numberWithInteger:FoundryPropertyTypeFirstName],
             @"breed": [NSNumber numberWithInteger:FoundryPropertyTypeLastName]
             };
}

@end
