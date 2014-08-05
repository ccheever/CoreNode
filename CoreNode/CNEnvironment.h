// Copyright 2014-present 650 Industries. All rights reserved.

@class CNProcess;
@class CNRuntime;

@interface CNEnvironment : NSObject

@property (strong, nonatomic, readonly) CNRuntime *runtime;
@property (strong, nonatomic, readonly) CNProcess *process;

@property (strong, nonatomic) JSValue *asyncListenerFlags;
@property (strong, nonatomic) JSValue *asyncListenerRunHandler;
@property (strong, nonatomic) JSValue *asyncListenerLoadHandler;
@property (strong, nonatomic) JSValue *asyncListenerUnloadHandler;

@property (strong, nonatomic) JSValue *tickInfo;
@property (strong, nonatomic) JSValue *tickHandler;

@property (nonatomic) BOOL usingDomains;
@property (strong, nonatomic) JSValue *domainArray;
@property (strong, nonatomic) JSValue *domainFlags;

@property (strong, nonatomic) NSMutableString *shouldCancelCheckImmediate;

- (instancetype)initWithProcess:(CNProcess *)process inContext:(JSContext *)context inRuntime:(CNRuntime *)runtime;
- (JSValue *)invokeCallbackBlock:(JSValue *(^)())block withTarget:(JSValue *)target;

@end


NSString * const CNTickInfoIndexKey;
NSString * const CNTickInfoLengthKey;
