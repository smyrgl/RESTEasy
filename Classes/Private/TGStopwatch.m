//
//  LSStopwatch.m
//  LevelSearchBenchmarking
//
//  Created by John Tumminaro on 4/18/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "TGStopwatch.h"

@interface TGStopwatch ()
@property (nonatomic, assign, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, assign, readwrite) CGFloat recordedTime;
@property (nonatomic, assign) uint64_t startTime;
@property (nonatomic, assign) uint64_t stopTime;
@end

@implementation TGStopwatch
{
    mach_timebase_info_data_t _info;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.running = NO;
        mach_timebase_info(&_info);
    }
    return self;
}

- (void)start
{
    self.running = YES;
    self.startTime = mach_absolute_time();
}

- (void)stop
{
    self.stopTime = mach_absolute_time();
    self.running = NO;
}

- (CGFloat)recordedTime
{
    uint64_t elapsed = self.stopTime - self.startTime;
    uint64_t nanos = elapsed * _info.numer / _info.denom;
    return (CGFloat)nanos / NSEC_PER_SEC;
}

- (uint64_t)stopTime
{
    if (!_stopTime) {
        return mach_absolute_time();
    } else {
        return _stopTime;
    }
}

@end
