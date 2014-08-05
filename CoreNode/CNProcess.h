// Copyright 2014-present 650 Industries. All rights reserved.

@protocol CNNativeBindingProtocol;

@interface CNProcess : NSObject

- (instancetype)initWithMainScript:(NSURL *)scriptUrl;
- (JSValue *)processObject;
- (JSValue *)processObjectForContext:(JSContext *)context;
- (void)registerBinding:(id<CNNativeBindingProtocol>)binding withName:(NSString *)name;

@end

bool envHasProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName);
JSValueRef envGetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
bool envSetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef *exception);
bool envDeleteProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
void envGetPropertyNames(JSContextRef context, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames);
