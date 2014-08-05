// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNProcess.h"

#import "CNEnvironment.h"
#import "CNNativeBindingProtocol.h"
#import "CNRuntime.h"
#import "CNRuntime_Internal.h"
#import "JSContext+Environment.h"
#import "JSContext+Runtime.h"
#import "JSValue+Errors.h"

#import <PromiseKit/PromiseKit.h>
#import <pwd.h>
#import <signal.h>
#import <unistd.h>
#import <sys/stat.h>

@interface CNProcess ()

@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSMutableDictionary *bindings;
@property (strong, nonatomic) NSMutableDictionary *bindingExportsCache;
@property (strong, nonatomic) JSManagedValue *managedProcessObject;

@end


@implementation CNProcess {
    NSURL *_mainScriptUrl;
}

- (instancetype)initWithMainScript:(NSURL *)scriptUrl
{
    if (self = [super init]) {
        _mainScriptUrl = [scriptUrl copy];

        self.startTime = [NSDate date];
        self.bindings = [NSMutableDictionary dictionary];
        self.bindingExportsCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (JSValue *)processObject
{
    return [self.managedProcessObject value];
}

- (JSValue *)processObjectForContext:(JSContext *)context
{
    if (self.managedProcessObject) {
        return [self.managedProcessObject value];
    }

    // Create a custom class for the process object so it can be detected
    JSClassDefinition processClassDefinition = kJSClassDefinitionEmpty;
    processClassDefinition.className = "process";
    JSClassRef processClass = JSClassCreate(&processClassDefinition);
    JSObjectRef processObjectRef = JSObjectMake([context JSGlobalContextRef], processClass, NULL);
    JSClassRelease(processClass);
    JSValue *processObject = [JSValue valueWithJSValueRef:processObjectRef inContext:context];

    processObject[@"versions"] = @{@"iOS": [UIDevice currentDevice].systemVersion};
    processObject[@"arch"] = [self cpuArchitecture];
    processObject[@"argv"] = @[@"node", [NSString stringWithUTF8String:[_mainScriptUrl fileSystemRepresentation]]];
    processObject[@"env"] = [self envObjectForContext:context];
    processObject[@"pid"] = [NSNumber numberWithInt:getpid()];
    processObject[@"execPath"] = [[NSBundle mainBundle] executablePath];

    // Set env variables for various paths related to the app
    setenv("CN_BUNDLE_PATH", [[[NSBundle mainBundle] bundlePath] UTF8String], 1);
    setenv("CN_RESOURCE_PATH", [[[NSBundle mainBundle] resourcePath] UTF8String], 1);
    setenv("CN_EXEC_PATH", [[[NSBundle mainBundle] executablePath] UTF8String], 1);
    setenv("CN_BUILTINPLUGINS_PATH", [[[NSBundle mainBundle] builtInPlugInsPath] UTF8String], 1);
    setenv("CN_SHAREDFRAMEWORKS_PATH", [[[NSBundle mainBundle] sharedFrameworksPath] UTF8String], 1);
    setenv("CN_SHAREDSUPPORT_PATH", [[[NSBundle mainBundle] sharedSupportPath] UTF8String], 1);

    NSDictionary *needImmediateCallbackDescriptor = @{
        JSPropertyDescriptorGetKey: ^BOOL {
            return [self needsImmediateCallback];
        },
        JSPropertyDescriptorSetKey: ^(BOOL value) {
            [self setNeedsImmediateCallback:value];
        },
    };
    [processObject defineProperty:@"_needImmediateCallback" descriptor:needImmediateCallbackDescriptor];

    processObject[@"reallyExit"] = ^(int code) {
        exit(code);
    };

    processObject[@"abort"] = ^{
        abort();
    };

    processObject[@"cwd"] = ^NSString *{
        char cwd[PATH_MAX];
        if (!getcwd(cwd, PATH_MAX)) {
            JSContext *context = [JSContext currentContext];
            context.exception = [JSValue valueWithNewErrorFromSyscall:@"cwd" errorCode:errno inContext:context];
            return nil;
        }
        return [NSString stringWithUTF8String:cwd];
    };

    processObject[@"chdir"] = ^(NSString * path){
        if (chdir([path UTF8String]) == -1) {
            JSContext *context = [JSContext currentContext];
            context.exception = [JSValue valueWithNewErrorFromSyscall:@"chdir" errorCode:errno inContext:context];
        }
    };

    processObject[@"_kill"] = ^int (int pid, int signal) {
        return kill(pid, signal);
    };

    processObject[@"umask"] = ^mode_t (mode_t mask) {
        return umask(mask);
    };

    processObject[@"getuid"] = ^uid_t {
        return getuid();
    };

    processObject[@"setuid"] = ^(JSValue *user) {
        uid_t uid;
        if ([user isString]) {
            NSNumber *resolvedUID = [self uidFromName:[user toString]];
            if (!resolvedUID) {
                return;
            }
            uid = [resolvedUID unsignedIntValue];
        } else {
            uid = [user toUInt32];
        }

        if (setuid(uid) == -1) {
            JSContext *context = [JSContext currentContext];
            context.exception = [JSValue valueWithNewErrorFromSyscall:@"setuid" errorCode:errno inContext:context];
        }
    };

    // Need to implement getuid, setuid, setgid, getgid, getgroups, setgroups, initgroups

    // Need to implement hrtime, dlopen, uptime, memoryUsage

    processObject[@"binding"] = ^JSValue *(NSString *name) {
        return [self binding:name];
    };

    processObject[@"_setupAsyncListener"] = ^(JSValue *flags, JSValue *runHandler, JSValue *loadHandler, JSValue *unloadHandler) {
        [self setupAsyncListenerWithFlags:flags runHandler:runHandler loadHandler:loadHandler unloadHandler:unloadHandler];
    };

    processObject[@"_setupNextTick"] = ^(JSValue *tickInfo, JSValue *tickHandler) {
        [self setupNextTick:tickInfo tickHandler:tickHandler];
    };

    processObject[@"_setupDomainUse"] = ^(JSValue *domainArray, JSValue *domainFlags) {
        [self setupDomainUse:domainArray flags:domainFlags];
    };

    NSURL *processFactoryUrl = [CNRuntime urlWithBase:context.runtime.bundleUrl filePath:@"js/process.js"];
    JSValue *processFactory = [context.runtime evaluateJSAtUrl:processFactoryUrl];
    processObject = [processFactory callWithArguments:@[processObject]];
    if (context.exception) {
        DDLogError(@"%@", context.exception);
        return nil;
    }

    self.managedProcessObject = [JSManagedValue managedValueWithValue:processObject];
    [context.virtualMachine addManagedReference:self.managedProcessObject withOwner:[context globalObject]];

    return processObject;
}

- (void)registerBinding:(id<CNNativeBindingProtocol>)binding withName:(NSString *)name
{
    self.bindings[name] = binding;
}

- (NSString *)cpuArchitecture
{
#if TARGET_IPHONE_SIMULATOR
    #if __LP64__
        return @"x64";
    #else
        return @"ia32";
    #endif
#else
    return @"arm";
#endif
}

- (JSValue *)envObjectForContext:(JSContext *)context
{
    JSClassDefinition envClassDefinition = kJSClassDefinitionEmpty;
    envClassDefinition.hasProperty = envHasProperty;
    envClassDefinition.getProperty = envGetProperty;
    envClassDefinition.setProperty = envSetProperty;
    envClassDefinition.deleteProperty = envDeleteProperty;
    envClassDefinition.getPropertyNames = envGetPropertyNames;
    JSClassRef envClass = JSClassCreate(&envClassDefinition);

    JSObjectRef envObject = JSObjectMake([context JSGlobalContextRef], envClass, NULL);
    JSClassRelease(envClass);
    return [JSValue valueWithJSValueRef:envObject inContext:context];
}

- (BOOL)needsImmediateCallback
{
    JSContext *context = [JSContext currentContext];
    return context.environment.shouldCancelCheckImmediate != nil;
}

- (void)setNeedsImmediateCallback:(BOOL)needsCallback
{
    JSContext *context = [JSContext currentContext];
    CNEnvironment *environment = context.environment;
    BOOL scheduled = environment.shouldCancelCheckImmediate != nil;
    if (needsCallback == scheduled) {
        return;
    }

    if (needsCallback) {
        NSAssert(!environment.shouldCancelCheckImmediate, @"Immediate callback check is already scheduled");

        NSMutableString *shouldCancelCheckImmediate = [NSMutableString string];
        environment.shouldCancelCheckImmediate = shouldCancelCheckImmediate;

        CNRuntime *runtime = context.runtime;
        __weak CNEnvironment *weakEnvironment = environment;

        dispatch_async(runtime.jsQueue, ^{
            if (![shouldCancelCheckImmediate boolValue]) {
                JSValue *processObject = [weakEnvironment.process processObject];
                [CNRuntime invokeTarget:processObject callbackMethod:@"_immediateCallback" withArguments:@[]];
            }
        });
    } else {
        [environment.shouldCancelCheckImmediate setString:@"YES"];
        environment.shouldCancelCheckImmediate = nil;
    }
}

- (NSNumber *)uidFromName:(NSString *)name
{
    const char *unixname = [name UTF8String];
    struct passwd passwordEntry;
    struct passwd *result;

    long bufferSize = sysconf(_SC_GETPW_R_SIZE_MAX);
    if (bufferSize == -1) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"sysconf" errorCode:-1 inContext:context];
        return nil;
    }

    char buffer[bufferSize];
    int error = getpwnam_r(unixname, &passwordEntry, buffer, sizeof(buffer), &result);
    if (error) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"getpwnam_r" errorCode:error inContext:context];
        return nil;
    }

    if (!result) {
        JSContext *context = [JSContext currentContext];
        NSString *message = [NSString stringWithFormat:@"setuid user ID \"%@\" does not exist", name];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }

    return @(passwordEntry.pw_uid);
}

- (JSValue *)binding:(NSString *)name
{
    JSValue *exports = self.bindingExportsCache[name];
    if (exports) {
        return exports;
    }

    JSValue *moduleLoadList = self.processObject[@"moduleLoadList"];
    [moduleLoadList invokeMethod:@"push" withArguments:@[[NSString stringWithFormat:@"Binding %@", name]]];

    JSContext *context = [JSContext currentContext];
    id<CNNativeBindingProtocol> binding = self.bindings[name];
    if (binding) {
        exports = [binding exportsForContext:context];
        NSAssert(exports, @"Binding for \"%@\" did not export anything", name);
    } else {
        NSString *message = [NSString stringWithFormat:@"No binding for \"%@\"", name];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }

    self.bindingExportsCache[name] = exports;
    return exports;
}

- (void)setupAsyncListenerWithFlags:(JSValue *)flags runHandler:(JSValue *)runHandler loadHandler:(JSValue *)loadHandler unloadHandler:(JSValue *)unloadHandler
{
    JSContext *context = [JSContext currentContext];
    CNEnvironment *environment = context.environment;
    environment.asyncListenerFlags = flags;
    environment.asyncListenerRunHandler = runHandler;
    environment.asyncListenerLoadHandler = loadHandler;
    environment.asyncListenerUnloadHandler = unloadHandler;
}

- (void)setupNextTick:(JSValue *)tickInfo tickHandler:(JSValue *)tickHandler
{
    JSContext *context = [JSContext currentContext];
    CNEnvironment *environment = context.environment;
    environment.tickInfo = tickInfo;
    environment.tickHandler = tickHandler;
}

- (void)setupDomainUse:(JSValue *)domainArray flags:(JSValue *)domainFlags
{
    JSContext *context = [JSContext currentContext];
    CNEnvironment *environment = context.environment;
    if (environment.usingDomains) {
        return;
    }
    environment.usingDomains = YES;

    JSValue *tickCallback = self.processObject[@"_tickDomainCallback"];
    self.processObject[@"_tickCallback"] = tickCallback;
    environment.tickHandler = tickCallback;

    environment.domainArray = domainArray;
    environment.domainFlags = domainFlags;
}

@end


#pragma mark - JSClassDefinition callbacks

bool envHasProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName)
{
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    return (bool)getenv([property UTF8String]);
}

JSValueRef envGetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception)
{
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    char *value = getenv([property UTF8String]);
    if (!value) {
        return NULL;
    }
    JSStringRef valueString = JSStringCreateWithUTF8CString(value);
    return JSValueMakeString(context, valueString);
}

bool envSetProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef *exception)
{
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    JSStringRef valueString = JSValueToStringCopy(context, value, exception);
    if (*exception) {
        return false;
    }

    NSString *envValue = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), valueString));
    JSStringRelease(valueString);

    if (setenv([property UTF8String], [envValue UTF8String], 1) == -1) {
        int errorCode = errno;
        JSContext *callingContext = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)context];
        JSValue *error = [JSValue valueWithNewErrorFromSyscall:@"setenv" errorCode:errorCode inContext:callingContext];
        *exception = [error JSValueRef];
        return false;
    }
    return true;
}

bool envDeleteProperty(JSContextRef context, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception)
{
    NSString *property = CFBridgingRelease(JSStringCopyCFString(CFAllocatorGetDefault(), propertyName));
    const char *variableName = [property UTF8String];
    if (!getenv(variableName)) {
        return false;
    }

    if (unsetenv(variableName) == -1) {
        int errorCode = errno;
        JSContext *callingContext = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)context];
        JSValue *error = [JSValue valueWithNewErrorFromSyscall:@"setenv" errorCode:errorCode inContext:callingContext];
        *exception = [error JSValueRef];
        return false;
    }
    return true;
}

void envGetPropertyNames(JSContextRef context, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames)
{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    for (NSString *variable in environment) {
        JSStringRef variableName = JSStringCreateWithCFString((__bridge CFStringRef)variable);
        JSPropertyNameAccumulatorAddName(propertyNames, variableName);
		JSStringRelease(variableName);
    }
}
