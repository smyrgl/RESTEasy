//
//  TGTestFactory.h
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTResource;

extern CGFloat TGTimedTestBlock (void (^block)(void));

@interface TGTestFactory : NSObject

+ (TGRESTResource *)testResource;
+ (TGRESTResource *)randomModelTestResource;
+ (NSArray *)randomModelTestResourcesWithCount:(NSUInteger)resourceCount;
+ (TGRESTResource *)testResourceWithParent:(TGRESTResource *)parent;
+ (TGRESTResource *)testResourceWithParents:(NSArray *)parents;
+ (TGRESTResource *)testResourceWithCountOfParents:(NSUInteger)parentCount;

+ (NSDictionary *)buildTestDataForResource:(TGRESTResource *)resource;
+ (NSArray *)buildTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count;
+ (void)createTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count;

@end

