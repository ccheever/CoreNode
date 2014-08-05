// Copyright 2014-present 650 Industries. All rights reserved.

#import "JSExport+Macros.h"

@protocol TimerWrapExports <JSExport>

@property (strong, nonatomic) NSNumber *repeatPeriod;
@property (strong, nonatomic) JSValue *onTimeout;

JSExportNullarySelectorAs(newTimer,
+ (instancetype)timerWrap
);

+ (double)now;

- (void)close;

JSExportAs(start,
- (void)startAfterDelay:(NSNumber *)delay withRepeatPeriod:(NSNumber *)period
);

- (void)stop;

@end


@interface TimerWrap : NSObject <TimerWrapExports>

@property (strong, nonatomic) NSNumber *repeatPeriod;
@property (strong, nonatomic) JSValue *onTimeout;

@end
