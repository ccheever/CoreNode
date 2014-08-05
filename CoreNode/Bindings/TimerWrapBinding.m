// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "TimerWrapBinding.h"

#import "CNRuntime.h"
#import "CNRuntime_Internal.h"
#import "JSContext+Runtime.h"
#import "TimerWrap.h"

@implementation TimerWrapBinding

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *exports = [JSValue valueWithNewObjectInContext:context];
    NSURL *bindingUrl = [CNRuntime urlWithBase:context.runtime.bundleUrl filePath:@"TimerWrap.js"];
    JSValue *factory = [context.runtime evaluateJSAtUrl:bindingUrl];
    exports[@"Timer"] = [factory callWithArguments:@[[TimerWrap class]]];
    return exports;
}

@end
