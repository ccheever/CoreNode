/**
 * Creates the ContextifyScript constructor function.
 */
(function(NativeContextifyScript) {
  function validateOptions(options) {
    if (options === undefined) {
      return {};
    }

    var type = typeof options;
    if (type === 'object' && options !== null || type === 'function') {
      return options;
    }
    throw new TypeError('options must be an object');
  }

  function ContextifyScript(code, options) {
    if (!this instanceof ContextifyScript) {
      throw new Error('Must call vm.Script as a constructor');
    }
    options = validateOptions(options);
    this._code = code;
    this._filename = options.filename === undefined
      ? 'evalmachine.<anonymous>'
      : options.filename;
    this._nativeScript = NativeContextifyScript.newScript();
  }

  ContextifyScript.prototype.runInContext = function(sandbox, options) {
    // TODO: support options.timeout
    return this._nativeScript.runInContext(
      this._code,
      sandbox,
      this._filename
    );
  };

  ContextifyScript.prototype.runInThisContext = function(options) {
    return this._nativeScript.runInThisContext(this._code, this._filename);
  };

  return ContextifyScript;
})
