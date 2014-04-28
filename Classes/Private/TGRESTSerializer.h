//
//  TGRESTSerializer.h
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTResource;

@protocol TGRESTSerializer <NSObject>

@required
+ (NSData *)dataWithSingularObject:(NSDictionary *)object resource:(TGRESTResource *)resource;
+ (NSData *)dataWithCollection:(NSArray *)collection resource:(TGRESTResource *)resource;


@end
