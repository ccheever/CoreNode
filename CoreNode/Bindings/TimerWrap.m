// Copyright 2014-present 650 Industries. All rights reserved.

#import "TimerWrap.h"

#import <uv/uv.h>

#import "CNRuntime.h"
#import "JSContext+Errors.h"
#import "JSContext+Runtime.h"

@implementation TimerWrap {
    NSTimer *_timer;
    JSManagedValue *_timeoutHandler;
}

+ (instancetype)timerWrap
{
    return [[self alloc] init];
}

+ (double)now
{
    uint64_t nanos = uv_hrtime();
    return nanos / 1000000.0;
}

- (JSValue *)onTimeout
{
    return [_timeoutHandler value];
}

- (void)setOnTimeout:(JSValue *)handler
{
    _timeoutHandler = [JSManagedValue managedValueWithValue:handler];
    JSContext *context = [JSContext currentContext];
    [context.virtualMachine addManagedReference:_timeoutHandler withOwner:self];
}

# pragma mark - Timer handles

- (void)close
{
    [self stop];
}

# pragma mark - Timer scheduling

- (void)startAfterDelay:(NSNumber *)delay withRepeatPeriod:(NSNumber *)period
{
    JSContext *context = [JSContext currentContext];
    [self stop];
    self.repeatPeriod = period;
    NSTimeInterval secondsToDelay = [delay doubleValue] / 1000;
    [self scheduleTimeout:secondsToDelay withRuntime:context.runtime];
}

- (void)stop
{
    [_timer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:NO];
    _timer = nil;
}

- (void)invokeTimeoutHandler:(NSTimer *)timer
{
    NSDictionary *timerInfo = [timer userInfo];
    CNRuntime *runtime = timerInfo[@"runtime"];

    dispatch_async(runtime.jsQueue, ^{
        NSNumber *status = @0;
        [CNRuntime invokeCallbackFunction:self.onTimeout withArguments:@[status]];

        NSTimeInterval seconds = [self.repeatPeriod doubleValue] / 1000;
        if (seconds > 0) {
            [self scheduleTimeout:seconds withRuntime:runtime];
        }
    });
}

- (void)scheduleTimeout:(NSTimeInterval)timeout withRuntime:(CNRuntime *)runtime
{
    NSAssert(![_timer isValid], @"Trying to schedule a timeout while the timer is already active");
    _timer = [NSTimer timerWithTimeInterval:timeout
                                     target:self
                                   selector:@selector(invokeTimeoutHandler:)
                                   userInfo:@{@"runtime": runtime}
                                    repeats:NO];
    [_timer setTolerance:MIN(0.001, timeout / 10)];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

@end
