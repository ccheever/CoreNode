// Copyright 2014-present 650 Industries. All rights reserved.

// An aliasing macro like JSExportAs for selectors that take zero arguments. It works by appending
// __JS_EXPORT_AS__{PropertyName}_ to the end of the selector's original name. There is a trailing
// underscore after the property name because Apple's aliasing code assumes that selectors take an
// argument and therefore end with a colon, which shouldn't be exposed to JavaScript.
#define JSExportNullarySelectorAs(PropertyName, Selector) \
@optional Selector##__JS_EXPORT_AS__##PropertyName##_; @required Selector

