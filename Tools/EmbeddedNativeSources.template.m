// Copyright 2014-present 650 Industries, Inc. All rights reserved.
// %(generated)s by Tools/generate_natives.py

#import "EmbeddedNativeSources.h"

@implementation EmbeddedNativeSources

static NSString * const sources[] = {%(sources_data)s};

+ (instancetype)sharedSources
{
    static dispatch_once_t predicate;
    static id sharedSources = nil;
    dispatch_once(&predicate, ^{
        sharedSources = [[self alloc] init];
    });
    return sharedSources;
}

- (NSUInteger)scriptCount
{
    return %(builtin_count)i;
}

- (NSUInteger)indexOfScript:(NSString *)moduleName
{
%(get_index_cases)s
    NSString *message = [NSString stringWithFormat:@"Unknown built-in %%@", moduleName];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
}

- (NSString *)nameOfScriptAtIndex:(NSUInteger)index
{
%(get_script_name_cases)s
    NSString *message = [NSString stringWithFormat:@"Unknown index %%lu", (unsigned long)index];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
}

- (NSString *)nameOfModuleAtIndex:(NSUInteger)index
{
%(get_module_name_cases)s
    NSString *message = [NSString stringWithFormat:@"Unknown index %%lu", (unsigned long)index];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
}

- (NSString *)sourceOfScriptAtIndex:(NSUInteger)index
{
    return sources[index];
}

@end
