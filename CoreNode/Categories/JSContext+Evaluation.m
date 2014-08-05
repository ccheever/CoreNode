// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "JSContext+Evaluation.h"

#import "JSContext+Errors.h"

@implementation JSContext (Evaluation)

- (JSValue *)evaluateScript:(NSString *)script inFile:(NSURL *)url
{
    return [self evaluateScript:script inFile:url fromLine:1];
}

- (JSValue *)evaluateScript:(NSString *)script inFile:(NSURL *)url fromLine:(NSUInteger)line
{
    JSGlobalContextRef context = [self JSGlobalContextRef];
    JSStringRef sourceCode = JSStringCreateWithCFString((__bridge CFStringRef)script);
    JSStringRef sourceURL = NULL;
    if (url) {
        sourceURL = JSStringCreateWithCFString((__bridge CFStringRef)[url absoluteString]);
    }
    JSValueRef exception = NULL;
    JSValueRef result = JSEvaluateScript(context, sourceCode, NULL, sourceURL, (int)line, &exception);

    if (sourceURL) {
        JSStringRelease(sourceURL);
    }
    JSStringRelease(sourceCode);

    if (exception) {
        return [self valueFromExceptionNotification:exception];
    }
    return [JSValue valueWithJSValueRef:result inContext:self];
}

@end
