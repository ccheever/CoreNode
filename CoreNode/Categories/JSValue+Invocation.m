// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "JSValue+Invocation.h"

#import "JSContext+Errors.h"

@implementation JSValue (Invocation)

- (JSValue *)bindThis:(id)thisValue
{
    return [self invokeMethod:@"bind" withArguments:thisValue];
}

- (JSValue *)callOnThis:(id)thisValue withArguments:(NSArray *)argumentArray
{
    JSContext *context = self.context;

    NSUInteger argumentCount = [argumentArray count];
    JSValueRef arguments[argumentCount];
    for (unsigned i = 0; i < argumentCount; ++i) {
        arguments[i] = [[JSValue valueWithObject:argumentArray[i] inContext:context] JSValueRef];
    }

    JSValueRef exception = NULL;
    JSObjectRef object = JSValueToObject([context JSGlobalContextRef], [self JSValueRef], &exception);
    if (exception) {
        return [context valueFromExceptionNotification:exception];
    }

    exception = NULL;
    JSObjectRef thisObject = JSValueToObject([context JSGlobalContextRef], [thisValue JSValueRef], &exception);
    if (exception) {
        return [context valueFromExceptionNotification:exception];
    }

    JSValueRef result = JSObjectCallAsFunction([context JSGlobalContextRef], object, thisObject, argumentCount, arguments, &exception);
    if (exception) {
        return [context valueFromExceptionNotification:exception];
    }

    return [JSValue valueWithJSValueRef:result inContext:context];
}

@end
