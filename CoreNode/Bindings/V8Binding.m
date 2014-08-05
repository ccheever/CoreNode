// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "V8Binding.h"

@implementation V8Binding

- (JSValue *)exportsForContext:(JSContext *)context
{
    return [JSValue valueWithObject:self inContext:context];
}

- (NSDictionary *)getHeapStatistics
{
    return @{};
}

- (void)startGarbageCollectionTracking:(JSValue *)handleGCUpdate
{
    DDLogVerbose(@"startGarbageCollectionTracking is unimplemented");
}

- (void)stopGarbageCollectionTracking
{
    DDLogVerbose(@"stopGarbageCollectionTracking is unimplemented");
}

@end
