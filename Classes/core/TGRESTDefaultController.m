//
//  TGRESTController.m
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import "TGRESTDefaultController.h"
#import "TGRESTResource.h"
#import "TGRESTStore.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerDataRequest.h>
#import <GCDWebServer/GCDWebServerURLEncodedFormRequest.h>
#import "TGPrivateFunctions.h"
#import "TGRESTEasyLogging.h"
#import "TGRESTSerializer.h"

@implementation TGRESTDefaultController

#pragma mark - Controller actions

+ (GCDWebServerResponse *)indexWithRequest:(GCDWebServerRequest *)request
                              withResource:(TGRESTResource *)resource
                               usingServer:(TGRESTServer *)server
{
    NSParameterAssert(request);
    NSParameterAssert(resource);
    NSParameterAssert(server);
    
    @autoreleasepool {
        if (request.URL.pathComponents.count > 2) {
            NSString *parentName = request.URL.pathComponents[1];
            NSString *parentID = request.URL.pathComponents[2];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", parentName];
            TGRESTResource *parent = [[resource.parentResources filteredArrayUsingPredicate:predicate] firstObject];
            NSError *error;
            NSArray *dataWithParent = [server.datastore getDataForObjectsOfResource:resource
                                                              withParent:parent
                                                        parentPrimaryKey:parentID
                                                                   error:&error];
            
            if (error) {
                return [self errorResponseBuilderWithError:error];
            }
            return [GCDWebServerDataResponse responseWithJSONObject:dataWithParent];
        }
        NSError *error;
        NSArray *allData = [server.datastore getAllObjectsForResource:resource error:&error];
        if (error) {
            return [self errorResponseBuilderWithError:error];
        }
        Class <TGRESTSerializer> serializer;
        if (server.serializers[resource.name]) {
            serializer = server.serializers[resource.name];
        } else {
            serializer = server.defaultSerializer;
        }
        
        return [GCDWebServerDataResponse responseWithJSONObject:[serializer dataWithCollection:allData resource:resource]];
    }
}

+ (GCDWebServerResponse *)showWithRequest:(GCDWebServerRequest *)request
                             withResource:(TGRESTResource *)resource
                              usingServer:(TGRESTServer *)server
{
    NSParameterAssert(request);
    NSParameterAssert(resource);
    NSParameterAssert(server);
    
    @autoreleasepool {
        NSString *lastPathComponent = request.URL.lastPathComponent;
        NSError *error;
        NSDictionary *resourceResponse = [server.datastore getDataForObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
        if (error) {
            return [self errorResponseBuilderWithError:error];
        }
        Class <TGRESTSerializer> serializer;
        if (server.serializers[resource.name]) {
            serializer = server.serializers[resource.name];
        } else {
            serializer = server.defaultSerializer;
        }
        
        return [GCDWebServerDataResponse responseWithJSONObject:[serializer dataWithSingularObject:resourceResponse resource:resource]];
    }
}

+ (GCDWebServerResponse *)createWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                                usingServer:(TGRESTServer *)server
{
    NSParameterAssert(request);
    NSParameterAssert(resource);
    NSParameterAssert(server);
    
    @autoreleasepool {
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
        NSDictionary *body;
        if ([request.contentType hasPrefix:@"application/json"]) {
            NSError *jsonError;
            body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:kNilOptions error:&jsonError];
            if (jsonError) {
                return [GCDWebServerResponse responseWithStatusCode:400];
            }
        } else if ([request.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSString* charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
            NSString* formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
            body = TGParseURLEncodedForm(formURLString);
        }
        
        Class <TGRESTSerializer> serializer;
        if (server.serializers[resource.name]) {
            serializer = server.serializers[resource.name];
        } else {
            serializer = server.defaultSerializer;
        }
        
        body = [serializer requestParametersWithBody:body resource:resource];
        NSError *error;
        NSDictionary *sanitizedBody = [self sanitizedPropertiesForResource:resource withProperties:body];
        if (sanitizedBody.allKeys.count == 0) {
            return [GCDWebServerResponse responseWithStatusCode:400];
        }
        
        NSDictionary *newObject = [server.datastore createNewObjectForResource:resource withProperties:sanitizedBody error:&error];
        
        body = nil;
        dataRequest = nil;
        sanitizedBody = nil;
        
        if (error) {
            return [self errorResponseBuilderWithError:error];
        }
        return [GCDWebServerDataResponse responseWithJSONObject:[serializer dataWithSingularObject:newObject resource:resource]];
    }
}

+ (GCDWebServerResponse *)updateWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                                usingServer:(TGRESTServer *)server
{
    NSParameterAssert(request);
    NSParameterAssert(resource);
    NSParameterAssert(server);
    
    @autoreleasepool {
        NSString *lastPathComponent = request.URL.lastPathComponent;
        if ([lastPathComponent isEqualToString:resource.name]) {
            return [GCDWebServerResponse responseWithStatusCode:403];
        }
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
        NSDictionary *body;
        if ([dataRequest.contentType hasPrefix:@"application/json"]) {
            NSError *jsonError;
            body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:kNilOptions error:&jsonError];
            if (jsonError) {
                TGLogError(@"Failed to deserialize JSON payload %@", jsonError);
                return [GCDWebServerResponse responseWithStatusCode:400];
            }
        } else if ([dataRequest.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSString *charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
            NSString *formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
            body = TGParseURLEncodedForm(formURLString);
        }
        
        Class <TGRESTSerializer> serializer;
        if (server.serializers[resource.name]) {
            serializer = server.serializers[resource.name];
        } else {
            serializer = server.defaultSerializer;
        }
        
        body = [serializer requestParametersWithBody:body resource:resource];
        
        NSDictionary *sanitizedBody = [self sanitizedPropertiesForResource:resource withProperties:body];
        if (sanitizedBody.allKeys.count == 0) {
            TGLogWarn(@"Request contains no keys matching valid parameters for resource %@ %@", resource.name, body);
            return [GCDWebServerResponse responseWithStatusCode:400];
        }
        
        NSError *error;
        NSDictionary *resourceResponse = [server.datastore modifyObjectOfResource:resource withPrimaryKey:lastPathComponent withProperties:sanitizedBody error:&error];
        
        body = nil;
        dataRequest = nil;
        sanitizedBody = nil;
        
        if (error) {
            TGLogError(@"Error modifying object of resource %@ with primary key %@", resource.name, lastPathComponent);
            return [self errorResponseBuilderWithError:error];
        } 
        
        return [GCDWebServerDataResponse responseWithJSONObject:[serializer dataWithSingularObject:resourceResponse resource:resource]];
    }
}

+ (GCDWebServerResponse *)destroyWithRequest:(GCDWebServerRequest *)request
                                withResource:(TGRESTResource *)resource
                                 usingServer:(TGRESTServer *)server
{
    NSParameterAssert(request);
    NSParameterAssert(resource);
    NSParameterAssert(server);
    
    @autoreleasepool {
        NSString *lastPathComponent = request.URL.lastPathComponent;
        if ([lastPathComponent isEqualToString:resource.name]) {
            return [GCDWebServerResponse responseWithStatusCode:403];
        }
        NSError *error;
        BOOL success = [server.datastore deleteObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
        
        if (!success) {
            return [self errorResponseBuilderWithError:error];
        }
        
        return [GCDWebServerResponse responseWithStatusCode:204];
    }
}


#pragma mark - Private

+ (GCDWebServerResponse *)errorResponseBuilderWithError:(NSError *)error
{
    NSParameterAssert(error);
    
    if (error.code == TGRESTStoreObjectAlreadyDeletedErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:410];
    } else if (error.code == TGRESTStoreObjectNotFoundErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:404];
    } else if (error.code == TGRESTStoreBadRequestErrorCode) {
        return [GCDWebServerResponse responseWithStatusCode:400];
    } else {
        return [GCDWebServerResponse responseWithStatusCode:500];
    }
}

+ (NSDictionary *)sanitizedPropertiesForResource:(TGRESTResource *)resource withProperties:(NSDictionary *)properties
{
    NSParameterAssert(resource);
    
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    for (NSString *key in resource.model.allKeys) {
        if (properties[key]) {
            [returnDict setObject:properties[key] forKey:key];
        }
    }
    return [NSDictionary dictionaryWithDictionary:returnDict];
}



@end
