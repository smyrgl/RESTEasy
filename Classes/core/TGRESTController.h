//
//  TGRESTController.h
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import <Foundation/Foundation.h>
#import "TGRESTSerializer.h"

@class GCDWebServerRequest;
@class GCDWebServerResponse;
@class TGRESTResource;
@class TGRESTServer;

/**
 If you want to go beyond simple CRUD then you need to customize the controller which means adopting this protocol.  Most common things that you need to do with `RESTEasy` should be adaquately met by either the default controller/serializer or by creating custom `TGSerializer` objects for your resources.  If it is just a question of changing the way data is represented to/from the API interface then the serializers are a much better option.
 
 So why would you want to create your own controller object?  Most of the reasons that you would want to mean you probably shouldn't be  using RESTEasy to being with but if you are determined then here are some examples:
 
 - You want to customize the default RESTful resource actions to do something that you can't get to work using the existing datastore options.
 - You want to add subactions of some kind that are transactional within the controller events (if you just want to do something before/after then you can use a subclass of `TGRESTDefaultController` instead and put your stuff before and after the calls to super.
 - You want to implement custom property validation and/or response codes (although again it might be easier to just subclass `TGRESTDefaultController`.
 - You want to add a general query system of some kind.
 
 The reason that this is discouraged is because although it is certainly possible to use classes that conform to `TGRESTController` to add whatever custom behavior you like, the more customization you add the less easy it becomes and the more you should probably be using another framework.  However if you really understand what you are getting into then go right ahead.
 
 ### Requests
 
 The request is of `GCDWebServerRequest` type and you should have a look at the documentation for GCDWebServer if you want to understand these better.  Also have a look at the implementation for `TGRESTDefaultController` but the general approach here is that the controller takes in the GCDWebServerRequest (representing a request to a given RESTful action), processes that action, performs it and then returns a response.  The controller is responsible for deserializing the JSON or FormURL encoded request as well as serializing it back into the response format to build and return a GCDWebServerResponse.
 
 ### Response
 
 Check out the documentation on GCDWebServerResponse for more on this but there are a number of subclasses like GCDWebServerDataResponse that will take a serialized JSON NSData object and take care of setting all of the appropriate content headers for the response.

 */

@protocol TGRESTController <NSObject>

@required

/**
 *  Called when the server receives a route matching a valid INDEX action for the given resource.
 *
 *  @param request  Request that was received.
 *  @param resource Resource that has matched the path regex.
 *  @param server    Server for the request.
 *
 *  @return Response for the action.
 */

+ (GCDWebServerResponse *)indexWithRequest:(GCDWebServerRequest *)request
                              withResource:(TGRESTResource *)resource
                            usingServer:(TGRESTServer *)server;

/**
 *  Called when the server receives a route matching a valid SHOW action for the given resource.
 *
 *  @param request  Request that was received.
 *  @param resource Resource that has matched the path regex.
 *  @param server    Server for the request.
 *
 *  @return Response for the action.
 */

+ (GCDWebServerResponse *)showWithRequest:(GCDWebServerRequest *)request
                             withResource:(TGRESTResource *)resource
                              usingServer:(TGRESTServer *)server;

/**
 *  Called when the server receives a route matching a valid CREATE action for the given resource.
 *
 *  @param request  Request that was received.
 *  @param resource Resource that has matched the path regex.
 *  @param server    Server for the request.
 *
 *  @return Response for the action.
 */

+ (GCDWebServerResponse *)createWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                                usingServer:(TGRESTServer *)server;

/**
 *  Called when the server receives a route matching a valid UPDATE action for the given resource.
 *
 *  @param request  Request that was received.
 *  @param resource Resource that has matched the path regex.
 *  @param server    Server for the request.
 *
 *  @return Response for the action.
 */

+ (GCDWebServerResponse *)updateWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                                usingServer:(TGRESTServer *)server;

/**
 *  Called when the server receives a route matching a valid DESTROY action for the given resource.
 *
 *  @param request  Request that was received.
 *  @param resource Resource that has matched the path regex.
 *  @param server    Server for the request.
 *
 *  @return Response for the action.
 */

+ (GCDWebServerResponse *)destroyWithRequest:(GCDWebServerRequest *)request
                                withResource:(TGRESTResource *)resource
                                 usingServer:(TGRESTServer *)server;
@end
