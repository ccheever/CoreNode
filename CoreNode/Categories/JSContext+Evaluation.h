// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

@interface JSContext (Evaluation)

- (JSValue *)evaluateScript:(NSString *)script inFile:(NSURL *)url;
- (JSValue *)evaluateScript:(NSString *)script inFile:(NSURL *)url fromLine:(NSUInteger)line;

@end
