// Copyright 2014-present 650 Industries. All rights reserved.

#define ManagedPropertyGetter(PropertyName) \
- (JSValue *)PropertyName \
{ \
    return [_##PropertyName value]; \
}

#define ManagedPropertySetter(PropertyName, Setter, Owner) \
- (void)Setter:(JSValue *)PropertyName \
{ \
    JSContext *context = [JSContext currentContext]; \
    _##PropertyName = [JSManagedValue managedValueWithValue:PropertyName]; \
    [context.virtualMachine addManagedReference:_##PropertyName withOwner:Owner]; \
}

#define ManagedPropertyAccessors(PropertyName, Setter, Owner) \
ManagedPropertyGetter(PropertyName) \
\
ManagedPropertySetter(PropertyName, Setter, Owner)
