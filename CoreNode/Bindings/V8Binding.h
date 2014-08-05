// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "CNNativeBindingProtocol.h"

@protocol V8BindingExports <JSExport>

- (NSDictionary *)getHeapStatistics;
- (void)startGarbageCollectionTracking:(JSValue *)handleGCUpdate;
- (void)stopGarbageCollectionTracking;

@end

@interface V8Binding : NSObject <V8BindingExports, CNNativeBindingProtocol>

@end
