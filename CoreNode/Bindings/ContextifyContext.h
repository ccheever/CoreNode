// Copyright 2014-present 650 Industries. All rights reserved.



@interface ContextifyContext : NSObject

@property (readonly, strong, nonatomic) JSContext *JSContext;

- (instancetype)initWithSandbox:(JSValue *)sandbox;
+ (void)contextifySandbox:(JSValue *)sandbox;
+ (instancetype)contextFromSandbox:(JSValue *)sandbox;

@end


bool globalHasProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName);
JSValueRef globalGetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
bool globalSetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef *exception);
bool globalDeleteProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
void globalGetPropertyNames(JSContextRef context, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames);
