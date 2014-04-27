//
//  TGRESTResource.h
//  Tests
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>


/**
 
 *  TGPropertyType defines the datatype of all of the objects in the resource model.  Every property in the model must use one of the defined types.
 
 */

typedef NS_ENUM(NSUInteger, TGPropertyType) {
    
    /**
     
     *  String type.
     
     */
    TGPropertyTypeString = 1,
    
    /**
     
     *  Integer type.
     
     */
    TGPropertyTypeInteger = 2,
    
    /**
     
     *  Float type.
     
     */
    TGPropertyTypeFloatingPoint = 3,
    
    /**
     
     *  Data blob type.
     
     */
    TGPropertyTypeBlob = 4,
    
    /**
     
     *  Anything that is not categorized by the other types (JSON for example).
     
     */
    TGPropertyTypeOther = 5
};


/**
 
 *  REST actions for a resource.
 
 */

typedef NS_OPTIONS(NSUInteger, TGResourceRESTActions) {
    
    /**
     
     *  GET includes index and show type actions on a resource and if it has parents defined it will include shallow nested routes for index on a parent.
     
     */
    TGResourceRESTActionsGET        = 1 << 0,
    
    /**
     
     *  POST includes create actions both on root objects and if there are any parents it will also create shallow nested create routes.
     
     */
    TGResourceRESTActionsPOST       = 1 << 1,
    
    /**
     
     *  Standard update action that generates routes for update actions on :resource_name/:id uris.  Is not nested.
     
     */
    TGResourceRESTActionsPUT        = 1 << 2,
    
    /**
     
     *  Standard delete action that generates routes for delete actions on :resource_name/:id uris.  Is not nested.
     
     */
    TGResourceRESTActionsDELETE     = 1 << 3
};

/**
 *  TGRESTResource represents the definition of the RESTFul resource you want to create.  In encapsulates the definition of model properties, route configuration for CRUD actions and relationships to other resources.
 */

@interface TGRESTResource : NSObject

/**
 *  Name of the resource that will be used as the base path for all RESTful routes.  For example a resource named "people" would generate routes of 'people/', 'people/:id', 'people/:id/:child_resource_name' (if child resources are defined) and ':parent_resource_name/:id/people' (if parents resources are defined).
    
    Note that a server can only have a single resource of a given name at a time and if you add another resource with the same name but a different model schema, the server will assume you are trying to update a resource model and will respond by flushing and recreating the schema.  So use care.
 
    TGRESTResource is immutable so its important to become familiar with the different constructor methods to get an idea of how best to create your resources with the desired level of configurability.
 */

@property (nonatomic, copy, readonly) NSString *name;

/**
 *  The model for the resource consisting of keys that represent property names and values that represent the property type (NSNumber wrappers around TGPropertyType values).
 */

@property (nonatomic, copy, readonly) NSDictionary *model;

/**
 *  The name of the resource primary key field.  Default is 'id' but can be optionall specified through some of the constructor methods.  Note that if you decide to provide a custom primary key it must be either of `TGPropertyTypeString` or `TGPropertyTypeInteger`.
 */

@property (nonatomic, copy, readonly) NSString *primaryKey;

/**
 *  Property type of the primary key.  By default this is `TGPropertyTypeInteger` but you can customize it to use `TGPropertyTypeString` if you like by specifying it in the model.  
 
    @warning Using a type other than `TGPropertyTypeString` or `TGPropertyTypeInteger` for a primary key will result in an exception.
 */

@property (nonatomic, assign, readonly) TGPropertyType primaryKeyType;

/**
 *  Array of `TGRESTResource` objects that have been defined as parents.  All parent resources will have shallow nested routes to their children for create and index actions.  
    
    @warning A resource might have the same resource as both a parent and child resource.  Although this use case was not a priority for this framework (especially since the default datastores do not include any sort of join table mechanism) it does allow for a crude but effective many-to-many modelling of resources.
 */

@property (nonatomic, copy, readonly) NSArray *parentResources;

/**
 *  Array of `TGRESTResource` objects that have been defined as children.
 */

@property (nonatomic, copy, readonly) NSArray *childResources;

/**
 *  A dictionary of foreign keys with the dictionary key being the parent resource name and the value being the property name for the foreign key that is in the model.  You do not need to explictly set this as a default foreign key will be generated for all parent resources.
 */

@property (nonatomic, copy, readonly) NSDictionary *foreignKeys;

/**
 *  NS_OPTIONS bitmask of REST verbs enabled for this resource.
 
 @see TGResourceRESTActions
 */

@property (nonatomic, assign, readonly) TGResourceRESTActions actions;

/**
 *  Simplest constructor method for `TGRESTResource`.  Will create a resource with default options including all `TGResourceRESTActions`, a default primary key of 'id' and no parent/child resources.  You just need to provide the name and model.
 *
 *  @param name  Name of the resource, must be unique on the server you are adding it to.
 *  @param model Keys representing property names and values that must be boxed values of `TGPropertyType`.
 *
 *  @return A new instance of `TGRESTResource`.
    @warning `name` and `model` cannot be nil and the model dictionary does undergo validation.  Exceptions will be thrown if the model does not conform to the standards specified.
 */

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model;

/**
 *  Constructor that includes explict settings for actions and primary key.
 *
 *  @param name    Name of the resource, must be unique on the server you are adding it to.
 *  @param model   Keys representing property names and values that must be boxed values of `TGPropertyType`.
 *  @param actions `TGResourceRESTActions` bitmask of enabled HTTP verbs.
 *  @param key     Custom name for the primary key of the resource.  Note that if you explictly set a primary key it MUST be defined in the model or else an exception will be thrown.
 *
 *  @return A new instance of `TGRESTResource`.
 */

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key;

/**
 *  Simplest constructor that includes support for relational resources.
 *
 *  @param name    Name of the resource, must be unique on the server you are adding it to.
 *  @param model   Keys representing property names and values that must be boxed values of `TGPropertyType`.
 *  @param actions `TGResourceRESTActions` bitmask of enabled HTTP verbs.
 *  @param key     Custom name for the primary key of the resource.  Note that if you explictly set a primary key it MUST be defined in the model or else an exception will be thrown.  Can be nil.
 *  @param parents Array of objects of `TGRESTResource` type.  For each parent resource added routes will be generated to this resource using shallow nesting (Create, Index actions only) and a foreign key will be added to the model with the default value of "parent_name_id".  Can be nil.
 *
 *  @return A new instance of `TGRESTResource`.
 */

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                    parentResources:(NSArray *)parents;

/**
 *  Designated constructor for this class, includes the ability to set explict primary keys for parent resources.
 *
 *  @param name    Name of the resource, must be unique on the server you are adding it to.
 *  @param model   Keys representing property names and values that must be boxed values of `TGPropertyType`.
 *  @param actions `TGResourceRESTActions` bitmask of enabled HTTP verbs.
 *  @param key     Custom name for the primary key of the resource.  Note that if you explictly set a primary key it MUST be defined in the model or else an exception will be thrown.  Can be nil.
 *  @param parents Array of objects of `TGRESTResource` type.  For each parent resource added routes will be generated to this resource using shallow nesting (Create, Index actions only) and a foreign key will be added to the model with the default value of "parent_name_id".  Can be nil.
 *  @param fkeys   Dictionary of explict foreign keys with the keys being the name of the parent resource and the values being the desired foreign key to be used.  Can be nil.
 *
 *  @return A new instance of `TGRESTResource`.
 */

+ (instancetype)newResourceWithName:(NSString *)name
                              model:(NSDictionary *)model
                            actions:(TGResourceRESTActions)actions
                         primaryKey:(NSString *)key
                    parentResources:(NSArray *)parents
                        foreignKeys:(NSDictionary *)fkeys;

@end
