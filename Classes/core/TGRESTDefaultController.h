//
//  TGRESTController.h
//  
//
//  Created by John Tumminaro on 4/27/14.
//
//

#import <Foundation/Foundation.h>
#import "TGRESTController.h"

/**
 Default implementation of the TGRESTController protocol that is used by TGRESTServer for all requests.  You can add a custom controller to `TGRESTServer` using the `-startWithOptions:` dictionary, but you should look at TGRESTSerializer to see if you can accomplish your goals with a custom serializer first.
 */

@interface TGRESTDefaultController : NSObject <TGRESTController>

@end
