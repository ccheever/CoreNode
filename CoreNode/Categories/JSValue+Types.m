// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "JSValue+Types.h"

#import "JSContext+Errors.h"

@implementation JSValue (Types)

- (BOOL)isFunction
{
    if (![self isObject]) {
        return NO;
    }

    JSContextRef context = [self.context JSGlobalContextRef];
    JSValueRef exception = NULL;
    JSObjectRef selfObject = JSValueToObject(context, [self JSValueRef], &exception);
    if (exception) {
        return [self.context boolFromExceptionNotification:exception];
    }
    return JSObjectIsFunction(context, selfObject);
}

- (BOOL)isTrue
{
    JSValue *trueValue = [JSValue valueWithBool:YES inContext:self.context];
    return [self isEqualToObject:trueValue];
}

- (BOOL)isFalse
{
    JSValue *falseValue = [JSValue valueWithBool:NO inContext:self.context];
    return [self isEqualToObject:falseValue];
}

- (BOOL)exists
{
    return ![self isNull] && ![self isUndefined];
}

- (JSStringRef)JSStringRef
{
    JSValueRef exception = NULL;
    JSStringRef string = JSValueToStringCopy([self.context JSGlobalContextRef], [self JSValueRef], &exception);
    if (exception) {
        [self.context boolFromExceptionNotification:exception];
        return NULL;
    }
    return string;
}

@end
