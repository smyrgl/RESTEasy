//
//  TGTestFactory.m
//  Tests
//
//  Created by John Tumminaro on 4/25/14.
//
//

#import "TGTestFactory.h"
#import "TGRESTResource.h"
#import <Gizou/Gizou.h>

@implementation TGTestFactory

+ (TGRESTResource *)testResource
{
    return [TGRESTResource newResourceWithName:@"person"
                                         model:@{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]}
                                        routes:nil
                                       actions:TGResourceRESTActionsDELETE | TGResourceRESTActionsGET | TGResourceRESTActionsPOST | TGResourceRESTActionsPUT
                                    primaryKey:nil];
}


+ (void)createTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count
{
    NSParameterAssert(resource);
    NSParameterAssert(count);
    
    NSMutableArray *objects = [NSMutableArray new];
    
    while (objects.count < count) {
        NSMutableDictionary *objectDictionary = [NSMutableDictionary new];
        for (NSString *key in resource.model.allKeys) {
            if (![key isEqualToString:resource.primaryKey]) {
                if ([resource.model[key] integerValue] == TGPropertyTypeString) {
                    [objectDictionary setObject:[GZNames name] forKey:key];
                } else if ([resource.model[key] integerValue] == TGPropertyTypeInteger) {
                    [objectDictionary setObject:[NSNumber numberWithInteger:arc4random_uniform(20) + 1] forKey:key];
                } else if ([resource.model[key] integerValue] == TGPropertyTypeFloatingPoint) {
                    [objectDictionary setObject:[NSNumber numberWithDouble:[GZLocations latitude]] forKey:key];
                } else if ([resource.model[key] integerValue] == TGPropertyTypeBlob) {
                    [objectDictionary setObject:[NSData data] forKey:key];
                }
            }
        }
        [objects addObject:objectDictionary];
    }
    
    [[TGRESTServer sharedServer] addData:[NSArray arrayWithArray:objects] forResource:resource];
}

@end
