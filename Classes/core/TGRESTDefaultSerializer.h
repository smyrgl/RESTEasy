//
//  TGRESTDefaultSerializer.h
//  
//
//  Created by John Tumminaro on 4/28/14.
//
//

#import <Foundation/Foundation.h>
#import "TGRESTSerializer.h"

/**
 Default implementation of the TGRESTSerializer protocol that is used for all resources by TGRESTServer.  This default implementation of these methods does nothing.
 */

@interface TGRESTDefaultSerializer : NSObject <TGRESTSerializer>

@end
