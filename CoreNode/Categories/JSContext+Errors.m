// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "JSContext+Errors.h"

JSStringRef JSContextCreateBacktrace(JSContextRef ctx, unsigned maxStackSize) CF_AVAILABLE(10_6, 7_0);

@implementation JSContext (Errors)

- (NSString *)backtrace
{
    JSStringRef backtraceJSString = JSContextCreateBacktrace([self JSGlobalContextRef], 10);
    NSString *backtrace = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), backtraceJSString));
    JSStringRelease(backtraceJSString);
    return backtrace;
}

- (BOOL)boolFromExceptionNotification:(JSValueRef)exception
{
    if (self.exceptionHandler) {
        self.exceptionHandler(self, [JSValue valueWithJSValueRef:exception inContext:self]);
    }
    return NO;
}

- (JSValue *)valueFromExceptionNotification:(JSValueRef)exception
{
    if (self.exceptionHandler) {
        self.exceptionHandler(self, [JSValue valueWithJSValueRef:exception inContext:self]);
    }
    return [JSValue valueWithUndefinedInContext:self];
}

@end
