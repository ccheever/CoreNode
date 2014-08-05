// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNNativeBindingProtocol.h"

@class CNRuntime;

@protocol FileSystemExports <JSExport>

- (void)FSInitialize:(JSValue *)statsConstructor;

@end

@interface FileSystemBinding : NSObject <FileSystemExports, CNNativeBindingProtocol>

- (instancetype)initWithRuntime:(CNRuntime *)runtime;

@end
