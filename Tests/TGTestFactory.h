//
//  TGTestFactory.h
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTResource;

@interface TGTestFactory : NSObject

+ (TGRESTResource *)testResource;
+ (TGRESTResource *)randomModelTestResource;
+ (NSArray *)randomModelTestResourcesWithCount:(NSUInteger)resourceCount;
+ (TGRESTResource *)testResourceWithParent:(TGRESTResource *)parent;
+ (TGRESTResource *)testResourceWithParents:(NSArray *)parents;
+ (TGRESTResource *)testResourceWithCountOfParents:(NSUInteger)parentCount;

+ (NSDictionary *)buildTestDataForResource:(TGRESTResource *)resource;
+ (void)createTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count;

@end
