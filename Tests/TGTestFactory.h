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

+ (void)createTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count;

@end
