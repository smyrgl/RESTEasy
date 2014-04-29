//
//  TGRESTInMemoryStore.h
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//
#import <Foundation/Foundation.h>
#import "TGRESTStore.h"

/**
 Concrete subclass of TGRESTStore, this is the default store type.  As the name suggests it doesn't do real "persistence", instead it simply stores everything in memory using a key/value store (aka an NSMutableDictionary).  Since there is no disk backing for this store type it will purge itself every time the server restarts (which can be an advantage depending on your use case) and if you need seed data you will need to manually load it each time using the `-addData:` method on TGRESTServer.
 */

@interface TGRESTInMemoryStore : TGRESTStore

@end
