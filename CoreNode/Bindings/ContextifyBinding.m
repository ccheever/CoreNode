// Copyright 2014-present 650 Industries. All rights reserved.

#import "ContextifyBinding.h"

#import "ContextifyScript.h"
#import "CNRuntime.h"
#import "CNRuntime_Internal.h"
#import "JSContext+Runtime.h"

@implementation ContextifyBinding

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *contextifyScriptConstructor = [self _constructorForContextifyScriptWithContext:context];
    self.ContextifyScript = [JSManagedValue managedValueWithValue:contextifyScriptConstructor];
    [context.virtualMachine addManagedReference:self.ContextifyScript withOwner:self];

    NSURL *bindingUrl = [CNRuntime urlWithBase:context.runtime.bundleUrl filePath:@"ContextifyBinding.js"];
    JSValue *contextifyBindingFactory = [context.runtime evaluateJSAtUrl:bindingUrl];
    if (context.exception) {
        return nil;
    }
    return [contextifyBindingFactory callWithArguments:@[self]];
}

- (JSValue *)_constructorForContextifyScriptWithContext:(JSContext *)context
{
    NSURL *scriptUrl = [CNRuntime urlWithBase:context.runtime.bundleUrl filePath:@"ContextifyScript.js"];
    JSValue *contextifyScriptFactory = [context.runtime evaluateJSAtUrl:scriptUrl];

    if (context.exception) {
        return nil;
    }
    return [contextifyScriptFactory callWithArguments:@[[ContextifyScript class]]];
}

#pragma mark - Bindings

- (JSValue *)makeContext:(JSValue *)sandbox
{
    if (![self sandboxIsObject:sandbox]) {
        return nil;
    }

    NSAssert(![ContextifyContext contextFromSandbox:sandbox], @"Sandbox is already associated with a VM context");
    [ContextifyContext contextifySandbox:sandbox];
    return sandbox;
}

- (BOOL)isContext:(JSValue *)sandbox
{
    if (![self sandboxIsObject:sandbox]) {
        return NO;
    }
    return (BOOL)[ContextifyContext contextFromSandbox:sandbox];
}

#pragma mark - Convenience methods

- (BOOL)sandboxIsObject:(JSValue *)sandbox {
    if (![sandbox isObject]) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromMessage:@"Sandbox must be an object" inContext:context];
        return NO;
    }
    return YES;
}

@end
