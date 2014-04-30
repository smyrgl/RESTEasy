//
//  TGRESTAbstractStore.h
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTServer;
@class TGRESTResource;


/**

`TGRESTStore` is an abstract superclass that defines the API through which the TGRESTController and TGRESTServer access the datastore.  The datastore will convert requests for resources by primaryKey (or relational keys) in CRUD operations and return the results as either a dictionary of key/value pairs matching the TGRESTResource model or an array of dictionaries (if applicable).
 
Although you do not need to understand this class in order to use **RESTEasy** it provides a mechanism for a wide variety of store types.  For example if you wanted to use an on-disk XML or JSON file directly you could create your own subclass of TGRESTStore and hook up to anything you like.
 
See TGRESTInMemoryStore for the default concrete implementation and TGRESTSqliteStore if you want a persistence option.
 */

@interface TGRESTStore : NSObject

@property (nonatomic, weak) TGRESTServer *server;

/**
 *  Returns a count of objects in the datastore for the given resource.  Asking for the count of objects for a resource not in the datastore will return 0.
 *
 *  @param resource A valid `TGRESTResource` that has been added to the datastore.
 *
 *  @return Count of resource objects in the datastore.
 */

- (NSUInteger)countOfObjectsForResource:(TGRESTResource *)resource;

/**
 *  Request for a single object of a given resource using the primary key value.
 *
 *  @param resource   Resource that the object is a member of.
 *  @param primaryKey The primary key for the object.
 *  @param error      If an error occurs on return will contain the `NSError` object.
 *
 *  @return Dictionary with keys matching the model property names and values matching the resource property values.
 */

- (NSDictionary *)getDataForObjectOfResource:(TGRESTResource *)resource
                              withPrimaryKey:(NSString *)primaryKey
                                       error:(NSError * __autoreleasing *)error;

/**
 *  Relational request to return all child objects owned by the parent object (one-to-many).
 *
 *  @param resource Resource of the child objects you want to find.
 *  @param parent   Resource of the parent object.
 *  @param key      Primary key of the parent object.
 *  @param error    If an error occurs on return will contain the `NSError` object.
 *
 *  @return Array of dictionary objects with each representing a child resource.  If the parent exists but has no children an empty array will be returned.
 */

- (NSArray *)getDataForObjectsOfResource:(TGRESTResource *)resource
                                  withParent:(TGRESTResource *)parent
                            parentPrimaryKey:(NSString *)key
                                       error:(NSError * __autoreleasing *)error;

/**
 *  Returns an array with all of the objects for a given resource.
 *
 *  @param resource Resource of the objects you want to return.
 *  @param error    If an error occurs on return will contain the `NSError` object.
 *
 *  @return Array of dictionary objects with each representing a child resource.  If there are no objects for the resource but it does exist in the datastore then an empty array will be returned.
 */

- (NSArray *)getAllObjectsForResource:(TGRESTResource *)resource
                                error:(NSError * __autoreleasing *)error;

/**
 *  Inserts a new object with the given properties and resource into the datastore.
 *
 *  @param resource   The resource of the object you wish to create.
 *  @param properties An dictionary with the keys matching property types in the resource model and the values being the property values you wish to assign.
 *  @param error      If an error occurs on return will contain the `NSError` object.
 *
 *  @return Dictionary of values after the object has been successfully created.  Note that this will include any default values not passed in with the property dictionary as well as the primary key.
 */

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource
                              withProperties:(NSDictionary *)properties
                                       error:(NSError * __autoreleasing *)error;

/**
 *  Modifies an object of a given resource and primary key.  Note that the property dictionary that is passed does not need to contain more than a single valid change property.
 *
 *  @param resource   The resource of the object you wish to modify.
 *  @param primaryKey The primary key of the object.
 *  @param properties The properties you wish to change.
 *  @param error      If an error occurs on return will contain the `NSError` object.
 *
 *  @return Dictionary containing the updated object after the update including all properties, not just the changed values.
 */

- (NSDictionary *)modifyObjectOfResource:(TGRESTResource *)resource
                          withPrimaryKey:(NSString *)primaryKey
                          withProperties:(NSDictionary *)properties
                                   error:(NSError * __autoreleasing *)error;

/**
 *  Deletes an object from the datastore.  Performs a "soft delete" where the object property values are wiped out but the primary key is kept so that requests on deleted objects can be differentiated from non-existing ones.  If the object has any child objects, the foreign key on the children should be set to NULL (the `TGRESTInMemoryStore` and `TGRESTSqliteStore` types do not support cascade delete rules).
 *
 *  @param resource   The resoure of the object you wish to delete.
 *  @param primaryKey The primary key of the object.
 *  @param error      If an error occurs on return will contain the `NSError` object.
 *
 *  @return `YES` if the delete was successful, `NO` if it was not.
 */

- (BOOL)deleteObjectOfResource:(TGRESTResource *)resource
                withPrimaryKey:(NSString *)primaryKey
                         error:(NSError * __autoreleasing *)error;

/**
 *  Adds a resource to the datastore.  Note that this method might get called with an identical existing resource model in the datastore which should be a no-op.  If a resource model has changed though the resource should be dropped and rebuit (no migrations expected when a resource model changes).  The method should not return until the datastore is ready to start accepting requests for this resource.
 *
 *  @param resource The resource to add to the datastore.
 */

- (void)addResource:(TGRESTResource *)resource;

/**
 *  Drops a resource from the datastore.  This will purge all data for the resource and destroy whatever the table structure that has been created for it is.  Equivalent to a `DROP TABLE` in SQL.
 *
 *  @param resource The resource to be dropped from the datastore.
 */

- (void)dropResource:(TGRESTResource *)resource;

@end

///----------------
/// @name Constants
///----------------

/**
 *  Default error domain for the Store.
 */

extern NSString * const TGRESTStoreErrorDomain;

/**
 *  Used when an object primary key is valid but has already been deleted.  Will lead to an HTTP 410 response.
 */

extern NSUInteger const TGRESTStoreObjectAlreadyDeletedErrorCode;

/**
 *  Used when an object cannot be found to perform the request request on.  Will lead to an HTTP 404 response.
 */

extern NSUInteger const TGRESTStoreObjectNotFoundErrorCode;

/**
 *  The parameters used to call the method were not valid for fulfilling the request.  For example a request for a resource that is not part of the datastore.  Indicates a code problem on the controller side since parameters are santized prior to datastore being called.
 */

extern NSUInteger const TGRESTStoreBadRequestErrorCode;

/**
 *  Error code for any other error condition which prevent fulfilling the request.  Which lead to a HTTP 500 server error response.
 */

extern NSUInteger const TGRESTStoreUnknownErrorCode;

