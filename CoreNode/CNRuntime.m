// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNRuntime.h"

#import <libkern/OSAtomic.h>
#import <CocoaLumberjack/DDLog.h>

@import JavaScriptCore;

#import "CNEnvironment.h"
#import "CNiOSBindings.h"
#import "CNProcess.h"
#import "ConstantsBinding.h"
#import "ContextifyBinding.h"
#import "FileSystemBinding.h"
#import "IosLoggingBinding.h"
#import "JSContext+Runtime.h"
#import "JSContext+Environment.h"
#import "JSContext+Evaluation.h"
#import "JSValue+Errors.h"
#import "NativesBinding.h"
#import "NativeSources.h"
#import "OSBinding.h"
#import "SmallocBinding.h"
#import "TimerWrapBinding.h"
#import "TTYWrapBinding.h"
#import "V8Binding.h"

static volatile int32_t CNRuntimeInstances = 0;

@implementation CNRuntime {
    const char * _jsQueueIdentifier;
    const char * _ioQueueIdentifier;
}

- (instancetype)initWithContext:(JSContext *)context rootUrl:(NSURL *)url
{
    if (self = [super init]) {
        _context = context;
        [CNRuntime _addLoggingExceptionHandlerToContext:context];
        _rootUrl = [url copy];

        NSString *nodeBundlePath = [[NSBundle mainBundle] pathForResource:@"CoreNode" ofType:@"bundle"];
        NSBundle *nodeBundle = [NSBundle bundleWithPath:nodeBundlePath];
        _bundleUrl = [[nodeBundle resourceURL] copy];

        _iOSBindings = [[CNiOSBindings alloc] init];

        int32_t instance = OSAtomicIncrement32(&CNRuntimeInstances) - 1;
        if (instance == 0) {
            _jsQueueIdentifier = "org.corenodejs.javascript";
            _ioQueueIdentifier = "org.corenodejs.io";
        } else {
            _jsQueueIdentifier = [[NSString stringWithFormat:@"org.corenodejs.javascript-%d", instance] cStringUsingEncoding:NSASCIIStringEncoding];
            _ioQueueIdentifier = [[NSString stringWithFormat:@"org.corenodejs.io-%d", instance] cStringUsingEncoding:NSASCIIStringEncoding];
        }

        _jsQueue = dispatch_queue_create(_jsQueueIdentifier, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_jsQueue, _jsQueueIdentifier, (void *)_jsQueueIdentifier, NULL);
        dispatch_set_target_queue(_jsQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

        _ioQueue = dispatch_queue_create(_ioQueueIdentifier, DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_ioQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

        _context.runtime = self;
    }
    return self;
}

+ (JSValue *)evaluateCallbackScript:(NSString *)script inContext:(JSContext *)context
{
    return [self evaluateCallbackScript:script inContext:context inFile:nil];
}

+ (JSValue *)evaluateCallbackScript:(NSString *)script inContext:(JSContext *)context inFile:(NSURL *)file
{
    return [self evaluateCallbackScript:script inContext:context inFile:file fromLine:1];
}

+ (JSValue *)evaluateCallbackScript:(NSString *)script inContext:(JSContext *)context inFile:(NSURL *)file fromLine:(NSUInteger)line
{
    CNEnvironment *environment = context.environment;
    JSValue *result = [environment invokeCallbackBlock:^JSValue *{
        return [context evaluateScript:script inFile:file fromLine:line];
    } withTarget:[environment.process processObject]];
    return result ?: [JSValue valueWithUndefinedInContext:context];
}

+ (JSValue *)invokeTarget:(JSValue *)target callbackMethod:(NSString *)method withArguments:(NSArray *)arguments
{
    JSContext *context = target.context;
    CNEnvironment *environment = context.environment;
    JSValue *result = [environment invokeCallbackBlock:^JSValue *{
        return [target invokeMethod:method withArguments:arguments];
    } withTarget:[environment.process processObject]];
    return result ?: [JSValue valueWithUndefinedInContext:context];
}

+ (JSValue *)invokeCallbackFunction:(JSValue *)function withArguments:(NSArray *)arguments
{
    JSContext *context = function.context;
    CNEnvironment *environment = context.environment;
    JSValue *result = [environment invokeCallbackBlock:^JSValue *{
        return [function callWithArguments:arguments];
    } withTarget:[environment.process processObject]];
    return result ?: [JSValue valueWithUndefinedInContext:context];
}

+ (JSValue *)invokeCallbackConstructor:(JSValue *)constructor withArguments:(NSArray *)arguments
{
    JSContext *context = constructor.context;
    CNEnvironment *environment = context.environment;
    JSValue *result = [environment invokeCallbackBlock:^JSValue *{
        return [constructor constructWithArguments:arguments];
    } withTarget:[environment.process processObject]];
    return result ?: [JSValue valueWithUndefinedInContext:context];
}

- (void)installNodeWithMainScript:(NSURL *)scriptUrl
{
    if (![self hasActiveJSQueue]) {
        DDLogWarn(@"Running Core Node off the JavaScript queue");
    }

    JSContext *context = _context;
    CNProcess *process = [[CNProcess alloc] initWithMainScript:scriptUrl];
    _environment = [[CNEnvironment alloc] initWithProcess:process inContext:context inRuntime:self];

    NSURL *preludeUrl = [CNRuntime urlWithBase:_bundleUrl filePath:@"js/prelude.js"];
    [self evaluateJSAtUrl:preludeUrl];

    // Register bindings to expose from process.binding()
    ConstantsBinding *constantsBinding = [[ConstantsBinding alloc] init];
    [process registerBinding:constantsBinding withName:@"constants"];

    NativesBinding *nativesBinding = [[NativesBinding alloc] init];
    // Override the Node built-ins with modules under ios-lib
    // We still need to port over stream from Browserify
    for (NSString *moduleName in @[@"buffer", @"child_process", @"config", @"console", @"crypto", @"fs", @"tty", @"util", @"zlib"]) {
        NSString *moduleFilename = [moduleName stringByAppendingPathExtension:@"js"];
        NSString *modulePath = [@"js/ios-lib" stringByAppendingPathComponent:moduleFilename];
        NSURL *scriptUrl = [CNRuntime urlWithBase:_bundleUrl filePath:modulePath];
        NSString *source = [[self class] _sourceFromURL:scriptUrl];
        [nativesBinding overrideModule:moduleName withSource:source];
    }
    [process registerBinding:nativesBinding withName:@"natives"];

    ContextifyBinding *contextifyBinding = [[ContextifyBinding alloc] init];
    [process registerBinding:contextifyBinding withName:@"contextify"];

    FileSystemBinding *fileSystemBinding = [[FileSystemBinding alloc] initWithRuntime:self];
    [process registerBinding:fileSystemBinding withName:@"fs"];

    OSBinding *osBinding = [[OSBinding alloc] init];
    [process registerBinding:osBinding withName:@"os"];

    SmallocBinding *smallocBinding = [[SmallocBinding alloc] init];
    [process registerBinding:smallocBinding withName:@"smalloc"];

    TimerWrapBinding *timerWrapBinding = [[TimerWrapBinding alloc] init];
    [process registerBinding:timerWrapBinding withName:@"timer_wrap"];

    TTYWrapBinding *ttyWrapBinding = [[TTYWrapBinding alloc] init];
    [process registerBinding:ttyWrapBinding withName:@"tty_wrap"];

    V8Binding *v8Binding = [[V8Binding alloc] init];
    [process registerBinding:v8Binding withName:@"v8"];

    IosLoggingBinding *iosLoggingBinding = [[IosLoggingBinding alloc] init];
    [process registerBinding:iosLoggingBinding withName:@"ioslogging"];

    self.iOSBindings.process = process;
    [process registerBinding:self.iOSBindings withName:@"ios"];

    // Load node.js from the native-source provider
    NSError *error = nil;
    id<NativeSourcesProtocol> sources = [NativeSources sourcesWithUrl:self.bundleUrl error:&error];
    if (error) {
        DDLogError(@"Error loading native sources: %@", [error localizedDescription]);
        return;
    }

    NSString *bootstrapSource = [sources sourceOfScriptAtIndex:[sources indexOfScript:CoreNodeScriptName]];
    NSString *bootstrapSourceFilename = [CoreNodeScriptName stringByAppendingPathExtension:@"js"];

    // NOTE: hacky
    JSValue *bootstrapFunction = [context evaluateScript:bootstrapSource inFile:[NSURL URLWithString:bootstrapSourceFilename]];
    JSValue *processObject = [process processObjectForContext:context];
    [bootstrapFunction callWithArguments:@[processObject]];

    if (context.exception) {
        DDLogError(@"Error bootstrapping Node: %@", context.exception);
    }
}

- (BOOL)hasActiveJSQueue
{
    return dispatch_get_specific(_jsQueueIdentifier) == _jsQueueIdentifier;
}

- (JSValue *)evaluateJSAtUrl:(NSURL *)url
{
    NSString *source = [[self class] _sourceFromURL:url];
    return [_context evaluateScript:source inFile:url];
}

+ (NSURL *)urlWithBase:(NSURL *)base filePath:(NSString *)filename
{
    return [filename length] ? [base URLByAppendingPathComponent:filename] : base;
}

+ (void)_addLoggingExceptionHandlerToContext:(JSContext *)context
{
    void (^oldExceptionHandler) (JSContext *, JSValue *) = context.exceptionHandler;
    context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        DDLogError(@"[JS] %@", [exception errorString]);
        if (oldExceptionHandler) {
            oldExceptionHandler(context, exception);
        }
    };
}

+ (NSString *)_sourceFromURL:(NSURL *)url
{
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        DDLogError(@"Error loading source from URL %@: %@", url, error);
    }
    return source;
}

@end
