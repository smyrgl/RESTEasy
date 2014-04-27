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
 *  Concrete subclass of TGRESTStore, this store type uses a sqlite3 database as the backing store offering a measure of persistence.  However this is still not meant for anything permanent which is reflected in the fact that this store will drop the schema and recreate the db anytime a resource model doesn't match the existing tables.  
 
    Note that the sqlite database is configured with FOREIGN KEY support so the performance of relational queries that are one-to-many should be pretty reasonable. 
 */

@interface TGRESTSqliteStore : TGRESTStore

@end
