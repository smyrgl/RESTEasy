//
//  TGPrivateFunctions.h
//  
//
//  Created by John Tumminaro on 4/24/14.
//
//

#import <Foundation/Foundation.h>

@class TGRESTResource;

extern NSString * TGApplicationDataDirectory(void);
extern NSString * TGExecutableName(void);
extern NSString * TGExtractHeaderValueParameter(NSString *value, NSString *name);
extern NSStringEncoding TGStringEncodingFromCharset(NSString *charset);
extern NSDictionary *TGParseURLEncodedForm(NSString *form);

extern NSString *TGIndexRegex(TGRESTResource *resource);
extern NSString *TGShowRegex(TGRESTResource *resource);
extern NSString *TGCreateRegex(TGRESTResource *resource);
extern NSString *TGUpdateRegex(TGRESTResource *resource);
extern NSString *TGDestroyRegex(TGRESTResource *resource);

extern uint8_t TGCountOfCores(void);
extern CGFloat TGTimedBlock (void (^block)(void));
extern CGFloat TGRandomInRange(CGFloat lowerRange, CGFloat upperRange);