//
//  TGRESTController.m
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import "TGRESTController.h"
#import "TGRESTResource.h"
#import "TGRESTStore.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerDataRequest.h>
#import <GCDWebServer/GCDWebServerURLEncodedFormRequest.h>
#import "TGPrivateFunctions.h"
#import "TGRESTEasyLogging.h"

@implementation TGRESTController

#pragma mark - Controller actions

+ (GCDWebServerResponse *)indexWithRequest:(GCDWebServerRequest *)request
                              withResource:(TGRESTResource *)resource
                            usingDatastore:(TGRESTStore *)store
{
    @autoreleasepool {
        if (request.URL.pathComponents.count > 2) {
            NSString *parentName = request.URL.pathComponents[1];
            NSString *parentID = request.URL.pathComponents[2];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", parentName];
            TGRESTResource *parent = [[resource.parentResources filteredArrayUsingPredicate:predicate] firstObject];
            NSError *error;
            NSArray *dataWithParent = [store getDataForObjectsOfResource:resource
                                                              withParent:parent
                                                        parentPrimaryKey:parentID
                                                                   error:&error];
            
            if (error) {
                return [self errorResponseBuilderWithError:error];
            }
            return [GCDWebServerDataResponse responseWithJSONObject:dataWithParent];
        }
        NSError *error;
        NSArray *allData = [store getAllObjectsForResource:resource error:&error];
        if (error) {
            return [self errorResponseBuilderWithError:error];
        }
        return [GCDWebServerDataResponse responseWithJSONObject:allData];
    }
}

+ (GCDWebServerResponse *)showWithRequest:(GCDWebServerRequest *)request
                             withResource:(TGRESTResource *)resource
                           usingDatastore:(TGRESTStore *)store
{
    @autoreleasepool {
        NSString *lastPathComponent = request.URL.lastPathComponent;
        NSError *error;
        NSDictionary *resourceResponse = [store getDataForObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
        if (error) {
            return [self errorResponseBuilderWithError:error];
        }
        return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
    }
}

+ (GCDWebServerResponse *)createWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                             usingDatastore:(TGRESTStore *)store
{
    @autoreleasepool {
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
        NSDictionary *body;
        if ([request.contentType hasPrefix:@"application/json"]) {
            NSError *jsonError;
            body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) {
                return [GCDWebServerResponse responseWithStatusCode:400];
            }
        } else if ([request.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSString* charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
            NSString* formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
            body = TGParseURLEncodedForm(formURLString);
        }
        NSError *error;
        NSDictionary *sanitizedBody = [self sanitizedPropertiesForResource:resource withProperties:body];
        if (sanitizedBody.allKeys.count == 0) {
            return [GCDWebServerResponse responseWithStatusCode:400];
        }
        
        NSDictionary *newObject = [store createNewObjectForResource:resource withProperties:sanitizedBody error:&error];
        
        body = nil;
        dataRequest = nil;
        sanitizedBody = nil;
        
        if (error) {
            return [self errorResponseBuilderWithError:error];
        }
        return [GCDWebServerDataResponse responseWithJSONObject:newObject];
    }
}

+ (GCDWebServerResponse *)updateWithRequest:(GCDWebServerRequest *)request
                               withResource:(TGRESTResource *)resource
                             usingDatastore:(TGRESTStore *)store
{
    @autoreleasepool {
        NSString *lastPathComponent = request.URL.lastPathComponent;
        if ([lastPathComponent isEqualToString:resource.name]) {
            return [GCDWebServerResponse responseWithStatusCode:403];
        }
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
        NSDictionary *body;
        if ([dataRequest.contentType hasPrefix:@"application/json"]) {
            NSError *jsonError;
            body = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) {
                TGLogError(@"Failed to deserialize JSON payload %@", jsonError);
                return [GCDWebServerResponse responseWithStatusCode:400];
            }
        } else if ([dataRequest.contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSString *charset = TGExtractHeaderValueParameter(request.contentType, @"charset");
            NSString *formURLString = [[NSString alloc] initWithData:dataRequest.data encoding:TGStringEncodingFromCharset(charset)];
            body = TGParseURLEncodedForm(formURLString);
        }
        
        NSDictionary *sanitizedBody = [self sanitizedPropertiesForResource:resource withProperties:body];
        if (sanitizedBody.allKeys.count == 0) {
            TGLogWarn(@"Request contains no keys matching valid parameters for resource %@ %@", resource.name, body);
            return [GCDWebServerResponse responseWithStatusCode:400];
        }
        
        NSError *error;
        NSDictionary *resourceResponse = [store modifyObjectOfResource:resource withPrimaryKey:lastPathComponent withProperties:sanitizedBody error:&error];
        
        body = nil;
        dataRequest = nil;
        sanitizedBody = nil;
        
        if (error) {
            TGLogError(@"Error modifying object of resource %@ with primary key %@", resource.name, lastPathComponent);
            return [self errorResponseBuilderWithError:error];
        }
        return [GCDWebServerDataResponse responseWithJSONObject:resourceResponse];
    }
}

+ (GCDWebServerResponse *)destroyWithRequest:(GCDWebServerRequest *)request
                                withResource:(TGRESTResource *)resource
                              usingDatastore:(TGRESTStore *)store
{
    @autoreleasepool {
        NSString *lastPathComponent = request.URL.lastPathComponent;
        if ([lastPathComponent isEqualToString:resource.name]) {
            return [GCDWebServerResponse responseWithStatusCode:403];
        }
        NSError *error;
        BOOL success = [store deleteObjectOfResource:resource withPrimaryKey:lastPathComponent error:&error];
        
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
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    for (NSString *key in resource.model.allKeys) {
        if (properties[key]) {
            [returnDict setObject:properties[key] forKey:key];
        }
    }
    return [NSDictionary dictionaryWithDictionary:returnDict];
}



@end
