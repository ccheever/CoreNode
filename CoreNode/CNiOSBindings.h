// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNNativeBindingProtocol.h"

@class CNProcess;

@interface CNiOSBindings : NSObject <CNNativeBindingProtocol>

@property (weak, nonatomic) CNProcess *process;

- (void)registerBinding:(id<CNNativeBindingProtocol>)binding withName:(NSString *)name;

@end
