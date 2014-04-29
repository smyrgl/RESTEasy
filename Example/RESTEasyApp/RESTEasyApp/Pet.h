//
//  Pet.h
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Person;

@interface Pet : NSObject <TGFoundryObject>

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *breed;
@property (nonatomic, copy) NSString *person_id;

@end
