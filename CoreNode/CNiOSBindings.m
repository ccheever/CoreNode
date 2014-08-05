// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNiOSBindings.h"

#import "CNProcess.h"

@interface CNiOSBindings ()

@property (strong, nonatomic) NSMutableDictionary *bindings;
@property (strong, nonatomic) NSMutableDictionary *bindingExportsCache;

@end


@implementation CNiOSBindings

- (instancetype)init
{
    if (self = [super init]) {
        self.bindings = [NSMutableDictionary dictionary];
        self.bindingExportsCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *iOSObject = [JSValue valueWithNewObjectInContext:context];
    iOSObject[@"binding"] = ^JSValue *(NSString *name) {
        return [self binding:name];
    };
    return iOSObject;
}

- (void)registerBinding:(id<CNNativeBindingProtocol>)binding withName:(NSString *)name
{
    self.bindings[name] = binding;
}

- (JSValue *)binding:(NSString *)name
{
    JSValue *exports = self.bindingExportsCache[name];
    if (exports) {
        return exports;
    }

    JSValue *processObject = [self.process processObject];
    JSValue *moduleLoadList = processObject[@"moduleLoadList"];
    [moduleLoadList invokeMethod:@"push" withArguments:@[[NSString stringWithFormat:@"Binding iOS %@", name]]];

    JSContext *context = [JSContext currentContext];
    id<CNNativeBindingProtocol> binding = self.bindings[name];
    if (binding) {
        exports = [binding exportsForContext:context];
        NSAssert(exports, @"iOS binding for \"%@\" did not export anything", name);
    } else {
        NSString *message = [NSString stringWithFormat:@"No binding for \"%@\"", name];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }

    self.bindingExportsCache[name] = exports;
    return exports;
}

@end
