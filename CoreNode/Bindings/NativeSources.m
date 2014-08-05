// Copyright 2014-present 650 Industries. All rights reserved.

#import "NativeSources.h"

#import "CNRuntime.h"
#import "EmbeddedNativeSources.h"

@interface NativeSources ()
@property (nonatomic, copy) NSArray *scriptUrls;
@end

@implementation NativeSources

+ (id<NativeSourcesProtocol>)sourcesWithUrl:(NSURL *)url error:(NSError **)error
{
    static id<NativeSourcesProtocol> sources;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
#if CORE_NODE_USE_BUNDLE
        sources = [self defaultSourcesWithUrl:url error:error];
#else
        sources = [EmbeddedNativeSources sharedSources];
#endif
    });
    return sources;
}

+ (instancetype)defaultSourcesWithUrl:(NSURL *)url error:(NSError **)error
{
    NSMutableArray *scriptPaths = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *specialScriptNames = @[CoreNodeScriptName, CoreNodeIOSScriptName];
    for (NSString *specialScriptName in specialScriptNames) {
        NSString *specialScriptFilename = [specialScriptName stringByAppendingPathExtension:@"js"];
        NSString *specialScriptPath = [@"js" stringByAppendingPathComponent:specialScriptFilename];
        NSURL *specialScriptUrl = [CNRuntime urlWithBase:url filePath:specialScriptPath];
        [scriptPaths addObject:specialScriptUrl];
    }

    NSURL *nodeLibraryDirectoryUrl = [CNRuntime urlWithBase:url filePath:@"node-lib"];
    NSArray *nodeLibraryFileUrls = [fileManager contentsOfDirectoryAtURL:nodeLibraryDirectoryUrl
                                              includingPropertiesForKeys:@[NSURLIsReadableKey, NSURLFileResourceTypeKey]
                                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                   error:error];
    if (nodeLibraryFileUrls) {
        return nil;
    }

    for (NSURL *builtInFileUrl in nodeLibraryFileUrls) {
        NSString *resourceType;
        NSNumber *isReadable;
        BOOL success;
        success = [builtInFileUrl getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:error];
        if (!success) {
            return nil;
        }
        success = [builtInFileUrl getResourceValue:&isReadable forKey:NSURLIsReadableKey error:error];
        if (!success) {
            return nil;
        }

        if ([NSURLFileResourceTypeRegular isEqualToString:resourceType] && [isReadable boolValue]) {
            [scriptPaths addObject:builtInFileUrl];
        }
    }

    NativeSources *sources = [[self alloc] init];
    sources.scriptUrls = scriptPaths;
    return sources;
}

- (NSUInteger)scriptCount
{
    return [_scriptUrls count];
}

- (NSUInteger)indexOfScript:(NSString *)moduleName
{
    for (NSUInteger i = 0; i < [_scriptUrls count]; i++) {
        NSString *name = [self _moduleNameFromUrl:_scriptUrls[i]];
        if ([moduleName isEqualToString:name]) {
            return i;
        }
    }
    NSString *message = [NSString stringWithFormat:@"Unknown built-in %@", moduleName];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
}

- (NSString *)nameOfScriptAtIndex:(NSUInteger)index
{
    NSString *moduleName = [self nameOfModuleAtIndex:index];
    return [NSString stringWithFormat:@"native %@", [moduleName stringByAppendingPathExtension:@"js"]];
}

- (NSString *)nameOfModuleAtIndex:(NSUInteger)index
{
    return [self _moduleNameFromUrl:_scriptUrls[index]];
}

- (NSString *)sourceOfScriptAtIndex:(NSUInteger)index
{
    NSError *error;
    NSString *source = [NSString stringWithContentsOfURL:_scriptUrls[index] encoding:NSUTF8StringEncoding error:&error];
    if (!source) {
        DDLogError(@"Error reading %@: %@", _scriptUrls[index], [error localizedDescription]);
    }
    return source;
}

- (NSString *)_moduleNameFromUrl:(NSURL *)url
{
    return [[url lastPathComponent] stringByDeletingPathExtension];
}

@end


NSString * const CoreNodeScriptName = @"node";
NSString * const CoreNodeIOSScriptName = @"iOS";
