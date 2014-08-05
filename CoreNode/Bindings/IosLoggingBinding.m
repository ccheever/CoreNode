// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "IosLoggingBinding.h"

#import <CocoaLumberjack/DDLog.h>

@implementation IosLoggingBinding

- (JSValue *)exportsForContext:(JSContext *)context {
    return [JSValue valueWithObject:self inContext:context];
}

- (void)logError:(NSString *)message
{
    DDLogError(@"%@", message);
}

- (void)logWarning:(NSString *)message
{
    DDLogWarn(@"%@", message);
}

- (void)logInfo:(JSValue *)message
{
    DDLogInfo(@"%@", message);
}

- (void)logDebug:(JSValue *)message
{
    DDLogDebug(@"%@", message);
}

- (void)logVerbose:(JSValue *)message
{
    DDLogVerbose(@"%@", message);
}

@end
