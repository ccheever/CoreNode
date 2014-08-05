// Copyright 2014-present 650 Industries. All rights reserved.

#import "ContextifyContext.h"
#import "JSContext+Errors.h"

@interface ContextifyContext ()

@property (strong, nonatomic) JSManagedValue *managedSandbox;

@end


@implementation ContextifyContext

const void *ContextifyContextKey = &ContextifyContextKey;

- (instancetype)initWithSandbox:(JSValue *)sandbox
{
    if (self = [super init]) {
        JSClassDefinition proxyGlobalClassDefinition = kJSClassDefinitionEmpty;
        proxyGlobalClassDefinition.hasProperty = globalHasProperty;
        proxyGlobalClassDefinition.getProperty = globalGetProperty;
        proxyGlobalClassDefinition.setProperty = globalSetProperty;
        proxyGlobalClassDefinition.deleteProperty = globalDeleteProperty;
        proxyGlobalClassDefinition.getPropertyNames = globalGetPropertyNames;
        JSClassRef proxyGlobalClass = JSClassCreate(&proxyGlobalClassDefinition);

        JSContext *callingContext = [JSContext currentContext];
        JSContextGroupRef contextGroup = JSContextGetGroup([callingContext JSGlobalContextRef]);
        JSGlobalContextRef sandboxContextRef = JSGlobalContextCreateInGroup(contextGroup, proxyGlobalClass);
        JSClassRelease(proxyGlobalClass);

        // Hold a reference to the sandbox object so the proxy global object can access it
        self.managedSandbox = [JSManagedValue managedValueWithValue:sandbox];
        [callingContext.virtualMachine addManagedReference:self.managedSandbox withOwner:sandbox];
        JSObjectRef global = JSContextGetGlobalObject(sandboxContextRef);
        JSObjectSetPrivate(global, (__bridge void *)self.managedSandbox);

        _JSContext = [JSContext contextWithJSGlobalContextRef:sandboxContextRef];
        JSGlobalContextRelease(sandboxContextRef);
    }
    return self;
}

+ (void)contextifySandbox:(JSValue *)sandbox;
{
    ContextifyContext *contextifyContext = [[self alloc] initWithSandbox:sandbox];
    sandbox[@"_context"] = contextifyContext;
}

+ (instancetype)contextFromSandbox:(JSValue *)sandbox
{
    JSValue *contextValue = sandbox[@"_context"];
    return [contextValue toObjectOfClass:[ContextifyContext class]];
}

+ (JSValue *)sandboxFromProxyGlobal:(JSObjectRef)global
{
    JSManagedValue *managedSandbox = (__bridge JSManagedValue *)JSObjectGetPrivate(global);
    return [managedSandbox value];
}

@end


#pragma mark - JSClassDefinition callbacks

bool globalHasProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName)
{
    JSValue *sandbox = [ContextifyContext sandboxFromProxyGlobal:object];
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    return [sandbox hasProperty:property];
}

JSValueRef globalGetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception)
{
    JSValue *sandbox = [ContextifyContext sandboxFromProxyGlobal:object];
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    if ([sandbox hasProperty:property]) {
        JSValue *value = [sandbox valueForProperty:property];
        return [value JSValueRef];
    }
    return NULL;
}

bool globalSetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef *exception)
{
    JSValue *sandbox = [ContextifyContext sandboxFromProxyGlobal:object];
    JSObjectRef sandboxObject = JSValueToObject(context, [sandbox JSValueRef], exception);
    if (*exception) {
        return false;
    }
    JSObjectSetProperty(context, sandboxObject, propertyName, value, kJSPropertyAttributeNone, exception);
    return *exception != NULL;
}

bool globalDeleteProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception)
{
    JSValue *sandbox = [ContextifyContext sandboxFromProxyGlobal:object];
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    if ([sandbox hasProperty:property]) {
        return [sandbox deleteProperty:property];
    }
    return false;
}

void globalGetPropertyNames(JSContextRef context, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames)
{
    JSValue *sandbox = [ContextifyContext sandboxFromProxyGlobal:object];
    JSValueRef exception = NULL;
    JSObjectRef sandboxObject = JSValueToObject(context, [sandbox JSValueRef], &exception);
    if (exception) {
        JSValue *error = [JSValue valueWithJSValueRef:exception inContext:sandbox.context];
        NSLog(@"Error enumerating object properties: %@", error);
        return;
    }

    JSPropertyNameArrayRef sandboxPropertyNames = JSObjectCopyPropertyNames(context, sandboxObject);
    size_t sandboxPropertyCount = JSPropertyNameArrayGetCount(sandboxPropertyNames);
    for (size_t i = 0; i < sandboxPropertyCount; i++) {
        JSStringRef propertyName = JSPropertyNameArrayGetNameAtIndex(sandboxPropertyNames, i);
        JSPropertyNameAccumulatorAddName(propertyNames, propertyName);
    }
}