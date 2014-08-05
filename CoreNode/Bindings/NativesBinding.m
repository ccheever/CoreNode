// Copyright 2014-present 650 Industries. All rights reserved.

#import "NativesBinding.h"

#import <CocoaLumberjack/DDLog.h>

#import "CNRuntime.h"
#import "EmbeddedNativeSources.h"
#import "JSContext+Runtime.h"
#import "NativeSources.h"

@interface NativesBinding ()

@property NSMutableDictionary *overrides;

@end


@implementation NativesBinding

- (instancetype)init
{
    if (self = [super init]) {
        self.overrides = [NSMutableDictionary dictionary];
    }
    return self;
}

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *exports = [JSValue valueWithNewObjectInContext:context];

    for (NSString *moduleName in self.overrides) {
        exports[moduleName] = self.overrides[moduleName];
    }

    NSError *error = nil;
    id<NativeSourcesProtocol> sources = [NativeSources sourcesWithUrl:context.runtime.bundleUrl error:&error];
    if (error) {
        DDLogError(@"Error loading native sources: %@", [error localizedDescription]);
        return nil;
    }

    NSUInteger count = [sources scriptCount];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *moduleName = [sources nameOfModuleAtIndex:i];
        if (self.overrides[moduleName] || [moduleName isEqualToString:CoreNodeScriptName]) {
            continue;
        }
        NSString *moduleSource = [sources sourceOfScriptAtIndex:i];
        exports[moduleName] = moduleSource;
    }

    return exports;
}

- (void)overrideModule:(NSString *)moduleName withSource:(NSString *)source
{
    self.overrides[moduleName] = source;
}

@end
