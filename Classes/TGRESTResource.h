//
//  TGRESTResource.h
//  Tests
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TGPropertyType) {
    TGPropertyTypeString = 1,
    TGPropertyTypeInteger = 2,
    TGPropertyTypeFloatingPoint = 3,
    TGPropertyTypeBlob = 4,
    TGPropertyTypeOther = 5
};

typedef NS_OPTIONS(NSUInteger, TGResourceRESTActions) {
    TGResourceRESTActionsGET        = 1 << 0,
    TGResourceRESTActionsPOST       = 1 << 1,
    TGResourceRESTActionsPUT        = 1 << 2,
    TGResourceRESTActionsDELETE     = 1 << 3
    
};

@interface TGRESTResource : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSDictionary *model;
@property (nonatomic, copy, readonly) NSString *primaryKey;
@property (nonatomic, copy, readonly) NSArray *parentResources;
@property (nonatomic, copy, readonly) NSArray *childResources;
@property (nonatomic, copy, readonly) NSDictionary *foreignKeys;
@property (nonatomic, assign, readonly) TGPropertyType primaryKeyType;
@property (nonatomic, assign, readonly) TGResourceRESTActions actions;

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model;

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key;

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                    parentResources:(NSArray *)parents;

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                    parentResources:(NSArray *)parents
                        foreignKeys:(NSDictionary *)fkeys;

@end
