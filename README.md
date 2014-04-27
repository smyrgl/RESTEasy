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

## Simple examples

Before I dive into everything that RESTEasy can do, let's start with a few basic examples and then I will show you how to bend this library to your will.  

### Setup the server with a simple resource

```objective-c

[[TGRESTServer sharedServer] startServerWithOptions:nil];

TGRESTResource *person = [TGRESTResource newResourceWithName:@"person" model:@{
														@"name": [NSNumber numberWithInteger:TGPropertyTypeString],
														@"numberOfKids": [NSNumber numberWithInteger:TGPropertyTypeInteger],
														@"kilometersWalked": [NSNumber numberWithInteger:TGPropertyTypeFloatingPoint],
														@"avatar": [NSNumber numberWithInteger:TGPropertyTypeBlob]
													}];

[[TGRESTServer sharedServer] addResource:person];

```

Our server is now ready to accept requests.  You can check this out using curl if you like by doing the following:

```
curl http://localhost:8888/person
[]
```

An empty array?  Well that's not very exciting but it is a start.  

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

