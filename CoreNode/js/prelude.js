/**
 * Prelude sets up the JavaScript environment before we bootstrap Node.
 */

// V8 defines an extra stack trace API: https://code.google.com/p/v8/wiki/JavaScriptStackTraceApi
if (Error.captureStackTrace === undefined) {
  Error.captureStackTrace = function captureStackTrace(error, constructor) { };
}
