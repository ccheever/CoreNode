// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "ContextifyScript.h"

#import "ContextifyContext.h"
#import "JSValue+Types.h"

@implementation ContextifyScript

+ (instancetype)script
{
    return [[self alloc] init];
}

- (JSValue *)runCode:(JSValue *)code inSandbox:(JSValue *)sandbox withFilename:(JSValue *)filename
{
    JSContext *callingContext = [JSContext currentContext];
    if (![sandbox isObject]) {
        NSString *message = @"Contextified sandbox must be an object";
        callingContext.exception = [JSValue valueWithNewErrorFromMessage:message inContext:callingContext];
        return nil;
    }

    ContextifyContext *contextifyContext = [ContextifyContext contextFromSandbox:sandbox];
    if (!contextifyContext) {
        NSString *message = @"Sandbox must have been converted to a context";
        callingContext.exception = [JSValue valueWithNewErrorFromMessage:message inContext:callingContext];
        return nil;
    }

    JSContext *sandboxContext = contextifyContext.JSContext;
    JSValue *result = [self runCode:code inContext:sandboxContext thisObject:NULL filename:filename];
    JSValue *exception = sandboxContext.exception;

    if (exception) {
        callingContext.exception = exception;
        return nil;
    }
    return result;
}

- (JSValue *)runCode:(JSValue *)code withFilename:(JSValue *)filename
{
    // NULL specifies that "this" should be the global object
    return [self runCode:code inContext:[JSContext currentContext] thisObject:NULL filename:filename];
}

- (JSValue *)runCode:(JSValue *)code inContext:(JSContext *)context thisObject:(JSObjectRef)thisObject filename:(JSValue *)filename
{
    JSStringRef script = [code JSStringRef];

    NSString *path = [filename toString];
    NSString *pathURL = [path isAbsolutePath] ? [@"file://" stringByAppendingString:path] : path;
    JSStringRef sourceURL = JSStringCreateWithCFString((__bridge CFStringRef)pathURL);

    JSValueRef exception = NULL;
    JSValueRef result = JSEvaluateScript([context JSGlobalContextRef], script, thisObject, sourceURL, 0, &exception);

    JSStringRelease(script);
    JSStringRelease(sourceURL);

    if (exception) {
        context.exception = [JSValue valueWithJSValueRef:exception inContext:context];
        return nil;
    }

    return [JSValue valueWithJSValueRef:result inContext:context];
}

@end
