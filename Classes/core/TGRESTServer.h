//
//  TGRESTServer.h
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>
#import "TGRESTSerializer.h"

@class TGRESTStore;
@class TGRESTResource;
@class TGRESTSerializer;

/**
 *  Options for setting the logging level.
 */

typedef NS_OPTIONS(NSUInteger, TGRESTServerLogLevel) {
    /**
     Log level off, will not log anything.
     */
    TGRESTServerLogLevelOff       = 0,
    /**
     Fatal messages only.
     */
    TGRESTServerLogLevelFatal     = 1 << 0,
    /**
     Error messages will be shown.
     */
    TGRESTServerLogLevelError     = 1 << 1,
    /**
     Warning messages will be shown.
     */
    TGRESTServerLogLevelWarn      = 1 << 2,
    /**
     All event messages will be shown.
     */
    TGRESTServerLogLevelInfo      = 1 << 3,
    /**
     Detailed event messages will be shown.
     */
    TGRESTServerLogLevelVerbose   = 1 << 4
};

/**
 *  TGRESTServer is the primary class for running and managing your RESTful server using RESTEasy.  It is designed to be as simple as possible to use, while providing reasonable options for configuration relevant to its intented use cases as a prototyping and testing server.  
 */

@interface TGRESTServer : NSObject

/**
 *  Indicates whether the server is running or not.
 */

@property (nonatomic, assign, readonly) BOOL isRunning;

/**
 *  The name of the server.
 */

@property (nonatomic, copy, readonly) NSString *serverName;

/**
 *  The base URL that the server can be reached at.
 */

@property (nonatomic, strong, readonly) NSURL *serverURL;

/**
 *  The bonjour name the server is broadcasting under.
 */

@property (nonatomic, copy, readonly) NSString *serverBonjourName;

/**
 *  The URL that the server bonjour services can be reached at.
 */

@property (nonatomic, copy, readonly) NSURL *serverBonjourURL;

/**
 *  The server datastore.
 */

@property (nonatomic, strong, readonly) TGRESTStore *datastore;

/**
 *  The default serializer used by the server.  By default this class is set to the TGRESTDefaultSerializer class and it is used for any resources that do not have a custom serializer.
 */
@property (nonatomic, strong, readonly) Class<TGRESTSerializer> defaultSerializer;

///------------------------
/// @name Creating a server
///------------------------

/**
 *  The default shared instance of the server.  This is the recommended way to use TGRESTServer.
 *
 *  @return A shared instance of TGRESTServer.
 */

+ (instancetype)sharedServer;

/**
 *  Creates and returns a new named server configured with the default options.  If you want to customize settings like the port number that is done on the -startServerWithOptions: method.
 *
 *  @param name Name you want the server to use.  This will influence the bounjour name as well as the name in response headers.
 *
 *  @return A new instance of TGRESTServer.
 */

+ (instancetype)serverWithName:(NSString *)name;

/**
 *  Starts server using the specified options dictionary.  For a complete list of keys and options see the constants for this class.
 *
 *  @param options Dictionary containing the configuration option keys and values.  Can be nil if you want to start with the default options.
 */

- (void)startServerWithOptions:(NSDictionary *)options;

/**
 *  Stops the server from receiving requests and unloads the datastore (meaning if you were using the default in-memory store then it will clear all of your server data).
 */
- (void)stopServer;

///---------------------------
/// @name Managing server data
///---------------------------

/**
 *  Returns the number of individual objects in the server datastore for the given resource.
 *
 *  @param resource The server managed resource you want an object count on.
 *
 *  @return Number of objects of the resource type in the datastore.
 */

- (NSUInteger)numberOfObjectsForResource:(TGRESTResource *)resource;

/**
 *  Get a dump of all the objects for a given resource in the server datastore.
 *
 *  @param resource The server managed resource you want an object dump of.
 *
 *  @return Array with dictionary representations of all of the objects in the datastore of the resource type.  Can be empty if the object count is zero.
 */

- (NSArray *)allObjectsForResource:(TGRESTResource *)resource;

/**
 *  Add data to the server by passing an array of dictionary objects containing property names for the keys and property values as the values.  For example if you want to load a JSON file to the server you can just convert it using the NSJSONSerialization method `+JSONObjectWithData:options:error:` and then if the property names don't need normalization against your resource model you can just pass the object directly to this method and it will load it into the datastore for you.
 *
 *  @param data     Array of dictionary representations of objects.
 *  @param resource Resource that is a representation of the data you are loading.
 */

- (void)addData:(NSArray *)data forResource:(TGRESTResource *)resource;

///--------------------------------
/// @name Managing server resources
///--------------------------------

/**
 *  List of all the resources currently being managed by the server.
 *
 *  @return Set of TGRESTResource objects.
 */

- (NSSet *)currentResources;

/**
 *  Adds a given resource to the server (CANNOT be performed when the server is running and will throw an exception).
 *
 *  @param resource TGRESTResource you want to add.
 */

- (void)addResource:(TGRESTResource *)resource;

/**
 *  Adds an array of resources to the server (CANNOT be performed when the server is running and will throw an exception).
 *
 *  @param resources Array of TGRESTResource objects you want to add.
 */

- (void)addResourcesWithArray:(NSArray *)resources;

/**
 *  Removes a resource from the server.
 *
 *  @param resource   TGRESTResource you want to remove.
 *  @param removeData Flag for if you want the server to pass `-dropResource:` to the datastore.
 */

- (void)removeResource:(TGRESTResource *)resource withData:(BOOL)removeData;

/**
 *  Removes all resources from the server.
 *
 *  @param removeData Flag for if you want the server to pass `-dropResource:` for each resource being managed to the datastore.
 */

- (void)removeAllResourcesWithData:(BOOL)removeData;

///-----------------------------
/// @name Advanced configuration
///-----------------------------

/**
 *  Current log level of the entire **RESTEasy** library.  Default to `TGRESTServerLogLevelWarn`.  Note that this is not a configuration for the server but a class method for a static variable which is used by all logging controlled by `RESTEasy`.  So you cannot set it on a per server basis.
 *
 *  @return Current log level.
 */

+ (TGRESTServerLogLevel)logLevel;

/**
 *  Sets the log level for `RESTEasy`.
 *
 *  @param level The log level you want to use.
 */

+ (void)setLogLevel:(TGRESTServerLogLevel)level;

/**
 *  Current resource serializers being used by the server which does not include the backing default serializer.  The serializers dictionary contains a list of keys which represent named resources and if there is a match the value of this dictionary (Class conforming to TGRESTSerializer) is used.  If no match is found the default serializer class is used.
 *
 *  @return Serializer classes currently registered with the server.
 */

- (NSDictionary *)serializers;

/**
 *  Sets a custom serializer class for the given resource.
 *
 *  @param class    Serializer class which conforms to TGRESTSerializer Protocol.
 *  @param resource Resource to register the serializer for.
 */

- (void)setSerializerClass:(Class)class forResource:(TGRESTResource *)resource;

/**
 *  Removes a serializer for a given resource if one exists.
 *
 *  @param resource Resource to remove the custom serializer from.
 */

- (void)removeCustomSerializerForResource:(TGRESTResource *)resource;

@end

///----------------
/// @name Constants
///----------------

/**
 Option key for the -startServerWithOptions: dictionary which sets the minimum latency for an API response.  Default is 0.00 seconds.
 */

extern NSString * const TGLatencyRangeMinimumOptionKey;

/**
 Option key for the -startServerWithOptions: dictionary which sets the maximum latency for an API response.  Default is 0.00 seconds.
 */

extern NSString * const TGLatencyRangeMaximumOptionKey;

/**
 Option key for the -startServerWithOptions: dictionary which sets the port number.  Default is 8888.
 */

extern NSString * const TGWebServerPortNumberOptionKey;

/**
 Option key for the -startServerWithOptions: dictionary which sets the datastore class you want the server to use.  Default is TGRESTInMemoryStore.
 */

extern NSString * const TGRESTServerDatastoreClassOptionKey;

/**
 Option key for the -startServerWithOptions: dictionary which sets the controller class for the server.  Default is TGRESTDefaultController.
 */

extern NSString * const TGRESTServerControllerClassOptionKey;

/**
 Option key for the -startServerWithOptions: dictionary which sets the default serializer class for the server.  Default is TGRESTDefaultSerializer.
 */

extern NSString * const TGRESTServerDefaultSerializerClassOptionKey;


///--------------------
/// @name Notifications
///--------------------

/**
 Posted when the server starts.  Note that the -startServerWithOptions: method is synchronous so this is only if you need a broadcast notification for classes other than the one calling to start the server.
 */

extern NSString * const TGRESTServerDidStartNotification;

/**
 Posted when the server shuts down.  Note that the -stopServer: method is synchronous so this is only if you need a broadcast notification for classes other than the one calling to stop the server.
 */

extern NSString * const TGRESTServerDidShutdownNotification;


