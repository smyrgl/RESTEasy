//
//  TGRESTEasyLogging.h
//  
//
//  Created by John Tumminaro on 4/26/14.
//
//

#ifndef _TGRESTEasyLogging_h
#define _TGRESTEasyLogging_h

#import "TGRESTServer.h"

#define TG_LOG_FLAG_FATAL   (1 << 0)  // 0...0001
#define TG_LOG_FLAG_ERROR   (1 << 1)  // 0...0010
#define TG_LOG_FLAG_WARN    (1 << 2)  // 0...0100
#define TG_LOG_FLAG_INFO    (1 << 3)  // 0...1000
#define TG_LOG_FLAG_VERBOSE (1 << 4)  // 0...1000

#define TG_LOG_LEVEL_OFF     0
#define TG_LOG_LEVEL_FATAL   (TG_LOG_FLAG_FATAL)
#define TG_LOG_LEVEL_ERROR   (TG_LOG_FLAG_FATAL | TG_LOG_FLAG_ERROR )                                                    // 0...0001
#define TG_LOG_LEVEL_WARN    (TG_LOG_FLAG_FATAL | TG_LOG_FLAG_ERROR | TG_LOG_FLAG_WARN)                                    // 0...0011
#define TG_LOG_LEVEL_INFO    (TG_LOG_FLAG_FATAL | TG_LOG_FLAG_ERROR | TG_LOG_FLAG_WARN | TG_LOG_FLAG_INFO)                    // 0...0111
#define TG_LOG_LEVEL_VERBOSE (TG_LOG_FLAG_FATAL | TG_LOG_FLAG_ERROR | TG_LOG_FLAG_WARN | TG_LOG_FLAG_INFO | TG_LOG_FLAG_VERBOSE) // 0...1111

#define LOG_ASYNC_ENABLED YES

#define LOG_ASYNC_ERROR   ( NO && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_WARN    (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_INFO    (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_VERBOSE (YES && LOG_ASYNC_ENABLED)

#ifndef LOG_MACRO

#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
NSLog (frmt, ##__VA_ARGS__)

#define LOG_MAYBE(async, lvl, flg, ctx, fnct, frmt, ...) \
do { if(lvl & flg) LOG_MACRO(async, lvl, flg, ctx, nil, fnct, frmt, ##__VA_ARGS__); } while(0)

#define LOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
LOG_MAYBE(async, lvl, flg, ctx, sel_getName(_cmd), frmt, ##__VA_ARGS__)

#define LOG_C_MAYBE(async, lvl, flg, ctx, frmt, ...) \
LOG_MAYBE(async, lvl, flg, ctx, __FUNCTION__, frmt, ##__VA_ARGS__)

#endif

#define TGLogFatal(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   [TGRESTServer logLevel], TG_LOG_FLAG_FATAL,   0, frmt, ##__VA_ARGS__)
#define TGLogError(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   [TGRESTServer logLevel], TG_LOG_FLAG_ERROR,   0, frmt, ##__VA_ARGS__)
#define TGLogWarn(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_WARN,    [TGRESTServer logLevel], TG_LOG_FLAG_WARN,    0, frmt, ##__VA_ARGS__)
#define TGLogInfo(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_INFO,    [TGRESTServer logLevel], TG_LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)
#define TGLogVerbose(frmt, ...) LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, [TGRESTServer logLevel], TG_LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)

#define TGLogCFatal(frmt, ...)   LOG_C_MAYBE(LOG_ASYNC_ERROR,   [TGRESTServer logLevel], TG_LOG_FLAG_FATAL,   0, frmt, ##__VA_ARGS__)
#define TGLogCError(frmt, ...)   LOG_C_MAYBE(LOG_ASYNC_ERROR,   [TGRESTServer logLevel], TG_LOG_FLAG_ERROR,   0, frmt, ##__VA_ARGS__)
#define TGLogCWarn(frmt, ...)    LOG_C_MAYBE(LOG_ASYNC_WARN,    [TGRESTServer logLevel], TG_LOG_FLAG_WARN,    0, frmt, ##__VA_ARGS__)
#define TGLogCInfo(frmt, ...)    LOG_C_MAYBE(LOG_ASYNC_INFO,    [TGRESTServer logLevel], TG_LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)
#define TGLogCVerbose(frmt, ...) LOG_C_MAYBE(LOG_ASYNC_VERBOSE, [TGRESTServer logLevel], TG_LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)


#endif
