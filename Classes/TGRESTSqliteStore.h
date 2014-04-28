//
//  TGRESTSqliteStore.h
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//

#import <Foundation/Foundation.h>
#import "TGRESTStore.h"

/**
 *  Concrete subclass of TGRESTStore, this store type uses a sqlite3 database as the backing store offering a measure of persistence.  However this is still not meant for anything permanent which is reflected in the fact that this store do a table drop anytime it adds a resource whose model doesn't match the existing structure.
 
    Note that the sqlite database is configured with `FOREIGN KEY` support and is thread safe as it has a DB queue and transactional operations where appropriate.  
 */

@interface TGRESTSqliteStore : TGRESTStore

@end
