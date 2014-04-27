//
//  TGPrivateFunctions.h
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>

extern NSString * TGApplicationDataDirectory(void);
extern NSString * TGExecutableName(void);
extern NSString * TGExtractHeaderValueParameter(NSString *value, NSString *name);
extern NSStringEncoding TGStringEncodingFromCharset(NSString *charset);
extern NSDictionary *TGParseURLEncodedForm(NSString *form);