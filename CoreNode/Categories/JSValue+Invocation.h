// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

@interface JSValue (Invocation)

- (JSValue *)bindThis:(id)thisValue;
- (JSValue *)callOnThis:(id)thisValue withArguments:(NSArray *)argumentArray;

@end
