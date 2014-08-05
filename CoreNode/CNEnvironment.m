// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNEnvironment.h"

#import "CNProcess.h"
#import "JSContext+Environment.h"
#import "JSManagedValue+Macros.h"
#import "JSValue+Errors.h"
#import "JSValue+Invocation.h"
#import "JSValue+Types.h"

@implementation CNEnvironment {
    BOOL _inCallback;

    JSManagedValue *_asyncListenerFlags;
    JSManagedValue *_asyncListenerRunHandler;
    JSManagedValue *_asyncListenerLoadHandler;
    JSManagedValue *_asyncListenerUnloadHandler;

    JSManagedValue *_tickInfo;
    JSManagedValue *_tickHandler;

    JSManagedValue *_domainArray;
    JSManagedValue *_domainFlags;

    __weak JSContext *_context;
}

- (instancetype)initWithProcess:(CNProcess *)process inContext:(JSContext *)context inRuntime:(CNRuntime *)runtime
{
    if (self = [super init]) {
        _process = process;
        _context = context;
        _runtime = runtime;
    }
    return self;
}

#pragma mark - AsyncListener

ManagedPropertyAccessors(asyncListenerFlags, setAsyncListenerFlags, [_process processObject])
ManagedPropertyAccessors(asyncListenerRunHandler, setAsyncListenerRunHandler, [_process processObject])
ManagedPropertyAccessors(asyncListenerLoadHandler, setAsyncListenerLoadHandler, [_process processObject])
ManagedPropertyAccessors(asyncListenerUnloadHandler, setAsyncListenerUnloadHandler, [_process processObject])

#pragma mark - Event loop ticks

ManagedPropertyAccessors(tickInfo, setTickInfo, [_process processObject])
ManagedPropertyAccessors(tickHandler, setTickHandler, [_process processObject])

#pragma mark - Domains

ManagedPropertyAccessors(domainArray, setDomainArray, [_process processObject])
ManagedPropertyAccessors(domainFlags, setDomainFlags, [_process processObject])

#pragma mark - Callbacks

- (JSValue *)invokeCallbackBlock:(JSValue *(^)())block withTarget:(JSValue *)target;
{
    JSContext *context = _context;
    context.exception = nil;

    // Guard against reentry so that callback tracing is set up only once per JS call stack
    if (_inCallback) {
        return block();
    }

    JSValue *processObject = [_process processObject];
    BOOL hasAsyncQueue = [target hasProperty:@"_asyncQueue"];
    if (hasAsyncQueue) {
        [self.asyncListenerLoadHandler callOnThis:processObject withArguments:@[target]];
        if (context.exception) {
            return nil;
        }
    }

    BOOL hasDomain = NO;
    if (self.usingDomains) {
        JSValue *domain = target[@"domain"];
        hasDomain = [domain isObject];
        if (hasDomain) {
            if ([domain[@"_disposed"] isTrue]) {
                return nil;
            }

            [domain[@"enter"] callWithArguments:@[]];
            if (context.exception) {
                return nil;
            }
        }
    }

    _inCallback = YES;
    JSValue *result = block();
    _inCallback = NO;
    if (context.exception) {
        return nil;
    }

    if (hasDomain) {
        JSValue *domain = target[@"domain"];
        [domain[@"exit"] callWithArguments:@[]];
        if (context.exception) {
            return nil;
        }
    }

    if (hasAsyncQueue) {
        [self.asyncListenerUnloadHandler callOnThis:processObject withArguments:@[target]];
        if (context.exception) {
            return nil;
        }
    }

    if ([self.tickInfo[@"_lastThrew"] toBool]) {
        self.tickInfo[@"_lastThrew"] = @(NO);
        return result;
    }

    if ([self.tickInfo[@"_inTick"] toBool]) {
        return result;
    }

    if ([self.tickInfo[CNTickInfoLengthKey] toUInt32] == 0) {
        self.tickInfo[CNTickInfoIndexKey] = @(0);
    }

    self.tickInfo[@"_inTick"] = @(YES);
    [self.tickHandler callOnThis:processObject withArguments:@[]];
    self.tickInfo[@"_inTick"] = @(NO);
    if (context.exception) {
        self.tickInfo[@"_lastThrew"] = @(YES);
        return nil;
    }

    return result;
}

@end

// Tick info keys must match those defined in node.js
NSString * const CNTickInfoIndexKey = @"0";
NSString * const CNTickInfoLengthKey = @"1";
