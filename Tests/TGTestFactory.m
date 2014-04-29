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
#import <mach/mach_time.h>

CGFloat TGTimedTestBlock (void (^block)(void))
{
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1.0;
    
    uint64_t start = mach_absolute_time ();
    block ();
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    uint64_t nanos = elapsed * info.numer / info.denom;
    return (CGFloat)nanos / NSEC_PER_SEC;
}

@implementation TGTestFactory

+ (TGRESTResource *)testResource
{
    return [TGRESTResource newResourceWithName:@"person"
                                         model:@{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]}];
}

+ (TGRESTResource *)randomModelTestResource
{
    return [TGRESTResource newResourceWithName:[GZWords word] model:@{
                                                                      [GZWords word]: [NSNumber numberWithInteger:TGPropertyTypeString],
                                                                      [GZWords word]: [NSNumber numberWithInteger:TGPropertyTypeInteger],
                                                                      [GZWords characters:5]: [NSNumber numberWithInteger:TGPropertyTypeFloatingPoint],
                                                                      [GZWords characters:5]: [NSNumber numberWithInteger:TGPropertyTypeBlob]
                                                                      }];    
}

+ (NSArray *)randomModelTestResourcesWithCount:(NSUInteger)resourceCount
{
    NSMutableArray *resourcesArray = [NSMutableArray new];
    
    for (int x = 0; x < resourceCount; x++) {
        [resourcesArray addObject:[self randomModelTestResource]];
    }
    
    return [NSArray arrayWithArray:resourcesArray];
}

+ (TGRESTResource *)testResourceWithParent:(TGRESTResource *)parent
{
    return [self testResourceWithParents:@[parent]];
}

+ (TGRESTResource *)testResourceWithParents:(NSArray *)parents
{
    return [TGRESTResource newResourceWithName:@"childResource"
                                         model:@{@"name": [NSNumber numberWithInteger:TGPropertyTypeString]}
                                       actions:TGResourceRESTActionsPOST | TGResourceRESTActionsGET | TGResourceRESTActionsPUT | TGResourceRESTActionsDELETE
                                    primaryKey:nil
                               parentResources:parents];
}

+ (TGRESTResource *)testResourceWithCountOfParents:(NSUInteger)parentCount
{
    NSMutableArray *parentsArray = [NSMutableArray new];
    
    for (int x = 0; x < parentCount; x++) {
        [parentsArray addObject:[self randomModelTestResource]];
    }
    
    return [self testResourceWithParents:[NSArray arrayWithArray:parentsArray]];
}

+ (NSDictionary *)buildTestDataForResource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
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
    
    return [NSDictionary dictionaryWithDictionary:objectDictionary];
}

+ (NSArray *)buildTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count
{
    NSMutableArray *returnArray = [NSMutableArray new];
    
    for (int x = 0; x < count; x++) {
        [returnArray addObject:[self buildTestDataForResource:resource]];
    }
    
    return [NSArray arrayWithArray:returnArray];
}

+ (void)createTestDataForResource:(TGRESTResource *)resource count:(NSUInteger)count
{
    NSParameterAssert(resource);
    NSParameterAssert(count);
    
    NSMutableArray *objects = [NSMutableArray new];
    
    while (objects.count < count) {
        [objects addObject:[self buildTestDataForResource:resource]];
    }
    
    [[TGRESTServer sharedServer] addData:[NSArray arrayWithArray:objects] forResource:resource];
}

@end
