//
//  TGRESTSerializer.h
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTResource;

/**
 *  If you want to customize the formatting of responses that are returned by the server then you can adopt this protocol.  Note that calling this a "serializer" is a bit of a misnomer--the methods described here are strictly for formatting the JSON response, they do not create it directly.  The default implementation of this protocol `TGRESTDefaultSerializer` in fact does nothing but return the dictionary objects unchanged.
 
    So what is the purpose of supporting the create of custom serializers?  If you really need to change the response format to match that of a server response for testing purposes then this will allow you to mutate the data and format in the JSON without changing the underlying data structure of the resource.  Some possible use cases for this are:
 
    - You have model data you want to load that doesn't match the JSON request/response representation and you don't want to change the source data itself.
    - You want to add custom attributes to the object representation to mimic the serialization structure that your server uses.  For example you can simulate values for pagination, properties that aren't part of the model or whatever custom nesting you like as the outputs of this will be serialized directly into JSON using `NSJSONSerialization`.  
    - Same as above but you want to remove or rename attributes or even combine them.  Doesn't matter, do anything you like!
    - By default the serializer returns the full embeded objects for any one-to-many relations but if you want to only include the IDs for example?  This makes it easy to do so.
 */

@protocol TGRESTSerializer <NSObject>

@required

/**
 *  Returns a representation for a given object that will be serialized to JSON directly after this step.  Used for Show and Update actions.
 *
 *  @param object   Dictionary for the object with keys matching the properties of the resource model and values of the object properties.
 *  @param resource Resource for the object.
 *
 *  @return JSON conformant object (either `NSDictionary` or `NSArray`) that can be serialized to build the response.
 
    @warning Although this might look a lot like the `NSJSONSerialization` methods you need to be aware that this method still returns an `NSDictionary` object NOT an `NSData` object.  In other words the actual JSON encoding is performed immediately after this step.
 */

+ (id)dataWithSingularObject:(NSDictionary *)object resource:(TGRESTResource *)resource;

/**
 *  Returns a representation of a collection of objects that will be serialized to JSON directly after this step.  Used for Index actions.
 *
 *  @param collection Array containing a dictionary representation of each object to return.  Could be an empty array if there are no results.
 *  @param resource   The resource that this collection of objects represents.
 *
 *  @return JSON conformant object (either `NSDictionary` or `NSArray`) that can be serialized to build the response.
 */

+ (id)dataWithCollection:(NSArray *)collection resource:(TGRESTResource *)resource;

/**
 *  Used for deserialization of parameters of a request for a Create or Update operation.  By default the controller assumes that the property names in the request need to exactly match the property names of the object they are trying to Create or Update but if you want to change the representation then you can do it here.  This is called AFTER the request properties have been converted from JSON or FormURL encoding to an dictionary of properties but BEFORE the controller applies parameter sanitization.
 *
 *  @param body     A dictionary representing the parameter keys and values in the request.
 *  @param resource The resource that this action is be used on.
 *
 *  @return A dictionary that matches the controller expected object representation.
 */

+ (NSDictionary *)requestParametersWithBody:(NSDictionary *)body resource:(TGRESTResource *)resource;

@end
