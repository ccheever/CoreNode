// Copyright 2014-present 650 Industries. All rights reserved.

@protocol NativeSourcesProtocol <NSObject>

- (NSUInteger)scriptCount;
- (NSUInteger)indexOfScript:(NSString *)name;
- (NSString *)nameOfScriptAtIndex:(NSUInteger)index;
- (NSString *)nameOfModuleAtIndex:(NSUInteger)index;
- (NSString *)sourceOfScriptAtIndex:(NSUInteger)index;

@end


@interface NativeSources : NSObject <NativeSourcesProtocol>

+ (id<NativeSourcesProtocol>)sourcesWithUrl:(NSURL *)url error:(NSError **)error;

@end

NSString * const CoreNodeScriptName;
NSString * const CoreNodeIOSScriptName;
