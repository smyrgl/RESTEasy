# RESTEasy

[![Build Status](https://travis-ci.org/smyrgl/RESTEasy.svg?branch=master)](https://travis-ci.org/smyrgl/RESTEasy)
[![Version](http://cocoapod-badges.herokuapp.com/v/RESTEasy/badge.png)](http://cocoadocs.org/docsets/RESTEasy)
[![Platform](http://cocoapod-badges.herokuapp.com/p/RESTEasy/badge.png)](http://cocoadocs.org/docsets/RESTEasy)

## What is RESTEasy?

As client developers a lot of our job is spent interacting with various webservices, usually of the RESTful type.  There's a reason why [AFNetworking](https://github.com/AFNetworking/AFNetworking) is probably the most popular third party library in the Cocoa ecosphere (to the point where I can scarcely remember the last project I did that didn't use it) and all because it makes interacting with webservices that much easier.  

However webservices integration still has a few thorns in client development that are hard to get around.

### The "dual development" problem

As nice as it would be to think that all client projects start with a finished API that's not often true.  How often do you work on a client project where you have a dependency on an API that is under heavy development?  Sure the general object data structure is probably known but it's very unlikely that you will have a fully stable API on day one of your development.

Furthermore once you start writing code that interacts with that API you are going to notice certain design changes that will make that API better.  No matter how good of a backend engineering team you are working with they are pretty much designing their API in a vacuum until the first client starts integrating with it but sadly by that time it is often too late for substantive changes.

### The prototyping problem

If you are anything like me then you might have solid Objective-C skills but your experience with backend code leaves a bit to be desired.  When I need to prototype an API because I want to try a client idea I will often put together something simple using [rails-api](https://github.com/rails-api/rails-api) or [sinatra](http://www.sinatrarb.com) and although these work pretty well its obviously not the sort of shift that I particularly enjoy when I am trying to prototype a client app since it forces me to switch between development environments constantly and those frameworks are much more geared towards building actual PRODUCTION applications so they are more complex then they need to be for simple prototyping jobs.  Furthermore they are meant for developing general purpose APIs whereas if you are just trying to prototype something for an iOS app its probably more than you need.

I've played with several other frameworks for this purpose such as [Deployd](https://github.com/deployd/deployd) and even serving static JSON using a small sinatra instance but none of them were ideal for someone who really wants something that I can contain within my Objective-C projects.

### The testing problem

Writing robust tests that interact with an API properly is HARD.  This is due to several reasons:

- If you want to test abnormal behavior like latency swings or timeouts then you either need to get a test enviornment for your API that supports it (good luck convincing your backend team to support that, especially for more than one-off testing) or you need to use some kind of freakish proxy that messes with your NSURLRequests.  Not fun or easy.
- If you are a good coder and you implement thorough testing in your app then you are going to be doing tests that rely on interactions with your API at some point either directly or indirectly.  But what API endpoint are you going to use?  You can't use your production service for anything but read-only data (or you will be populating your production system with a lot of junk) and test systems aren't exactly known for uptime or latency guarantees.  You could stub out the services for your tests using a proxy and some static returns but this can be a lot of work to do right, especially if you want to simulate real network response times.

Sadly most people either end up writing very brittle integration tests and then throw up their hands at all the ghost failures they see (sometimes missing actual bugs in their code in the process) or they just avoid tests that hit those webservices entirely.  This might be why (or at least one of a few reasons) unit testing on iOS hasn't advanced to quite the degree that it has on a lot of server side languages.

### You can RESTEasy

RESTEasy is my proposed solution to these problems.  Want a RESTful server setup quick?  Just do this?

```objective-c
#import <RESTEasy/RESTEasy.h>

[[TGRESTServer sharedServer] startServerWithOptions:nil];

```

You now have a RESTful API server running inside your Objective-C client project!  It can be reached via HTTP calls just like any other server and its ready to start accepting requests right away.  But that's only the beginning of the power this unlocks...

## Beginner stuff

Before I dive into everything that RESTEasy can do, let's start with a few basic examples and then I will show you how to bend this library to your will.  

### Setup the server with a simple resource

```objective-c
TGRESTResource *people = [TGRESTResource newResourceWithName:@"people" model:@{
														@"name": [NSNumber numberWithInteger:TGPropertyTypeString],
														@"numberOfKids": [NSNumber numberWithInteger:TGPropertyTypeInteger],
														@"kilometersWalked": [NSNumber numberWithInteger:TGPropertyTypeFloatingPoint],
														@"avatar": [NSNumber numberWithInteger:TGPropertyTypeBlob]
													}];

[[TGRESTServer sharedServer] addResource:people];

[[TGRESTServer sharedServer] startServerWithOptions:nil];

```

Our server is now ready to accept requests!  

### Basic CRUD

You can check that the server is working using curl if you like by doing the following:

```
curl http://localhost:8888/people
[]
```

An empty array?  Well that's not very exciting but it is a start.  So how do we get data in there?  Well we could just start the normal REST way:

```
curl \
	-X POST \
	-H "Content-Type: application/json" \
	-d '{"name":"john","numberOfKids":1}' \
	http://10.0.1.66:8888/people

{"numberOfKids":1,"id":1,"kilometersWalked":null,"name":"john","avatar":null}
```

Huzzah!  Our first object returned successfully.  We could also repeat our first request and get this:

```
[{"numberOfKids":1,"id":1,"kilometersWalked":null,"name":"john","avatar":null}]
```

Ok then, let's try updating it so the name is "jeff" instead.

```
curl \
	-X PUT \
	-H "Content-Type: application/json" \
	-d '{"name":"jeff"}' \
	http://10.0.1.66:8888/people/1

{"numberOfKids":1,"id":1,"kilometersWalked":null,"name":"jeff","avatar":null}
```

Not bad.  How about a delete?

```
curl \
	-X DELETE \
	http://10.0.1.66:8888/people/1
```

Works just like you'd expect.

### Loading data

Of course we don't want to have to load our entire dataset just with API calls.  Fortunately **RESTEasy** has you covered with some very simple ways to load your sample data.

Let's say your data is in JSON with identical property names to the resource model you defined for the sake of this example--we can load it doing something like this:

```objective-c
// Let's assume this was assigned to the resource we created before
TGRESTResource *people = ...

// First lets get the JSON from disk and parse it
NSString *pathToJSON = [[NSBundle mainBundle] pathForResource:@"testdata" ofType:@"json"];
NSData *rawJSON = [NSData dataWithContentsOfFile:pathToJSON];
NSError *parsingError;
id json = [NSJSONSerialization JSONObjectWithData:rawJSON options:kNilOptions error:&parsingError];

if (!error) {
	// Now pass it to the server
	[[TGRESTServer sharedServer] addData:json forResource:people];
}
```

The objects that you pass will first be sanitized and harvested of any matching parameters and as long as at least one property name matches it will injest the entire JSON object and create data for each.  Easy right?

### Relational data and routes

You can set one-to-many relations between your resources really easily.  All you have to do is something like this:

```objective-c
TGRESTResource *people = [TGRESTResource newResourceWithName:@"people" 
																					model:@{
               															@"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                                           	@"numberOfKids": [NSNumber numberWithInteger:TGPropertyTypeInteger],
                                           	@"kilometersWalked": [NSNumber numberWithInteger:TGPropertyTypeFloatingPoint],
                                           	@"avatar": [NSNumber numberWithInteger:TGPropertyTypeBlob]
                                           }];
        
TGRESTResource *cars = [TGRESTResource newResourceWithName:@"cars"
                                        model:@{
                                  							@"name": [NSNumber numberWithInteger:TGPropertyTypeString],
                                  							@"color": [NSNumber numberWithInteger:TGPropertyTypeString]
                                  			}
                        								actions:TGResourceRESTActionsDELETE | TGResourceRESTActionsGET | TGResourceRESTActionsPOST | TGResourceRESTActionsPUT
                     										primaryKey:nil
                												parentResources:@[people]];
        
        [[TGRESTServer sharedServer] addResource:people];
        [[TGRESTServer sharedServer] addResource:cars];
```

And by doing that we get the following default routes created:

| Resource | Verb   | URI Pattern      | Result                             |
|----------|--------|------------------|------------------------------------|
| people   | GET    | /people          | List of all people                 |
| people   | GET    | /people/:id      | Single person by id                |
| people   | POST   | /people          | Creates a new person               |
| people   | PUT    | /people/:id      | Updates a person by id             |
| people   | DELETE | /people/:id      | Deletes a person by id             |
| cars     | GET    | /cars            | List of all cars                   |
| cars     | GET    | /cars/:id        | Single car by id                   |
| cars     | GET    | /people/:id/cars | All cars for person by id          |
| cars     | POST   | /cars            | Creates a new car                  |
| cars     | POST   | /people/:id/cars | Creates a new car for person by id |
| cars     | PUT    | /cars/:id        | Updates a car by id                |
| cars     | DELETE | /cars/:id        | Deletes a car by id                |

This follows a concept similar to shallow nesting as [described here](http://guides.rubyonrails.org/routing.html#nested-resources) with a few minor differences (which mostly involve restriction of nested resources which is not the point of this library).

## Intermediate stuff

Ok the above should give you a pretty good idea of how to get started quickly.  But what about customization?

Although **RESTEasy** is supposed to be about mocking webservices not creating exact replicas, there are a few areas where you might understandably need a little more than the basics.  **RESTEasy** was architected to make this as simple as possible without jeprodizing the core mission of being approachable and dead simple to setup and start using.

### Customizing the request/response representations

So your data doesn't exactly match the JSON representations that your server provides?  There are a few reasons this might happen:

- Property names are just plain different.
- Certain properties are interpreted or calculated at runtime.
- You have structure to your JSON which isn't directly connected to the underlying data
- Cthulhu knows why but how do I not have to think about it?

Yes you could normalize the data before importing (and that's cerainly an option) but if you want more control look no further than the `TGRESTSerializer` protocol for all your data representation needs.

This protocol is pretty simple, it defines three class methods:

```objective-c
+ (id)dataWithSingularObject:(NSDictionary *)object resource:(TGRESTResource *)resource;
+ (id)dataWithCollection:(NSArray *)collection resource:(TGRESTResource *)resource;
+ (NSDictionary *)requestParametersWithBody:(NSDictionary *)body resource:(TGRESTResource *)resource;
```

The first two are for generating responses from either a single object or collection of objects after they are retrieved from the datastore and the third method provides the paramters of an incoming request which you can normalize however you like.  It's actually wrong to call this a serializer since it doesn't actually serialize/deserialize anything (although when you think about sequencing of events these methods are invoked either directly before or directly after "real" serialization), it is instead a way of morphing the data into whatever you want it to look like before it goes in or comes out of the server resource controller.

You can change property names, formatting, inject default or static values, anything you like.  The philosophy here is that if you are going to need to perform an ugly hack to get your data representations to look right then lets do a proper ugly hack and isolate it from the rest of the framework.

There is a default implementation of a class that conforms to the `TGRESTSerializer` protocol called `TGRESTDefaultSerializer`.  It is really instructive to look at its implementation file.

```objective-c
#import "TGRESTDefaultSerializer.h"

@implementation TGRESTDefaultSerializer

+ (id)dataWithSingularObject:(NSDictionary *)object resource:(TGRESTResource *)resource
{
    NSParameterAssert(object);
    NSParameterAssert(resource);
    
    return object;
}

+ (id)dataWithCollection:(NSArray *)collection resource:(TGRESTResource *)resource
{
    NSParameterAssert(collection);
    NSParameterAssert(resource);
    
    return collection;
}

+ (NSDictionary *)requestParametersWithBody:(NSDictionary *)body resource:(TGRESTResource *)resource
{
    NSParameterAssert(resource);
    
    return body;
}

@end
```

So it does absolutely nothing which is exactly the point.  If you want to customize the requests or responses to make them fit the way an existing API works you can do so and you don't need to touch your data representations as they will be blissfully ignorant of all of this.

### Loading a custom serializer

Once you create a class that implements the `TGRESTSerializer` protocol you need to load it onto the server.  There are two ways of doing this.

#### Default serializer

This is the serializer that is used if there are no specified resource serializers.  If you want to contain it all in one class with a single set of rules this is an easy way to go, just remember that unlike the resource serializers you can only set this when starting the server up.

To set the default serializer do this:

```objective-c
NSDictionary *options = @{TGRESTServerDefaultSerializerClassOptionKey: [MyCustomSerializer class]};
[[TGRESTServer sharedServer] startServerWithOptions:options];
```

Notice that you are passing the **class** of your custom serializer not an instance.  

### Resource serializer

You can set a resource serializer anytime you like, even when the server is running.  The way it works is that the resource controller will look for a serializer for the resource first and only go to the default serializer if it can't find one.  So this lets you assign custom serializers where necessary but you can always count on the default being there if you haven't defined one.

Setting a serializer for a resource is as easy as:

```objective-c
[[TGRESTServer sharedServer] setSerializerClass:[MyCustomSerializer class] forResource:people];
```

Then to remove it:

```objective-c
[[TGRESTServer sharedServer] removeCustomSerializerForResource:people];
```

### Setting latency minimum and maximums

**Coming Soon**

### Setting timeout frequencies

**Coming Soon**

## Advanced stuff

Really want to hack on **RESTEasy**?  Well there are a few other things you can do.

### Custom controllers

You want to do something beyond basic CRUD on your resources?  While **RESTEasy** is not and will never be Rails it does have the ability to swap out the default controller for another one.  This won't change the default routes but what it will do is give you full customizability over the controller actions (Index, Show, Create, Update, Destroy).  Check out the `TGRESTController` protocol or the `TGRESTDefaultController` class for some ideas on where you can go with this as you can either subclass `TGRESTDefaultController` if you want to keep the super CRUD methods or create your own conforming controller.

Once you have it you just load it onto the server much like you do with the custom serializers.

```objective-c
NSDictionary *options = @{TGRESTServerControllerClassOptionKey: [MyCustomController class]};
[[TGRESTServer sharedServer] startServerWithOptions:options];
```

Just be sure this is really what you want as this is an advanced feature that most people won't need or want to bother with.  You should have exhausted what you can do with a custom `TGRESTSerializer` before you even think about using this.

### Different store types

By default there are two store types: in-memory and sqlite and they both have their uses.  But you'll notice that there are both subclasses of an abstract superclass called `TGRESTStore`.  If you want to hook up your REST API to something else (anything from a JSON file to a remote webservice) you can do so by creating a custom store that implements all the methods on `TGRESTStore`.

```objective-c
- (NSUInteger)countOfObjectsForResource:(TGRESTResource *)resource;

- (NSDictionary *)getDataForObjectOfResource:(TGRESTResource *)resource
                              withPrimaryKey:(NSString *)primaryKey
                                       error:(NSError * __autoreleasing *)error;

- (NSArray *)getDataForObjectsOfResource:(TGRESTResource *)resource
                                  withParent:(TGRESTResource *)parent
                            parentPrimaryKey:(NSString *)key
                                       error:(NSError * __autoreleasing *)error;

- (NSArray *)getAllObjectsForResource:(TGRESTResource *)resource
                                error:(NSError * __autoreleasing *)error;

- (NSDictionary *)createNewObjectForResource:(TGRESTResource *)resource
                              withProperties:(NSDictionary *)properties
                                       error:(NSError * __autoreleasing *)error;

- (NSDictionary *)modifyObjectOfResource:(TGRESTResource *)resource
                          withPrimaryKey:(NSString *)primaryKey
                          withProperties:(NSDictionary *)properties
                                   error:(NSError * __autoreleasing *)error;

- (BOOL)deleteObjectOfResource:(TGRESTResource *)resource
                withPrimaryKey:(NSString *)primaryKey
                         error:(NSError * __autoreleasing *)error;

- (void)addResource:(TGRESTResource *)resource;

- (void)dropResource:(TGRESTResource *)resource;
```

If you want more details on implementing your own concrete store class check out the documentation for `TGRESTStore` as well as both of the existing implementations `TGRESTInMemoryStore` and `TGRESTSqliteStore`.

## Usage

If you want to play with the example app, run the test suite yourself or submit a pull request then clone the repo and run `pod install` from the root directory first then open `RESTEasy.xcworkspace`.

### Documentation

Available as a [Cocoadocs](http://cocoadocs.org/docsets/RESTEasy) docset or you can download the repo and run 'rake docs:generate'.  All of the classes are fully documented.

### Example App

Have a look at the /Example folder.

## Requirements

Designed for OSX 10.8 and iOS 6.0 and above.

## Installation

RESTEasy is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "RESTEasy"

## Acknowledgements 

This library would not have been possible without a couple of fantastic subprojects that it makes use of. 

- [GCDWebServer](https://github.com/swisspol/GCDWebServer) GCD based HTTP server which is used as the underpinning for both the persisting and non-persisting REST server components.
- [sqlite](https://www.sqlite.org) Used as the embedded database for the persisting REST server option.
- [FMDB](https://github.com/ccgus/fmdb) Objective-C wrapper that makes interacting with sqlite a lot more straightforward.

## Author

John Tumminaro, john@tinylittlegears.com

## License

RESTEasy is available under the MIT license. See the LICENSE file for more info.

