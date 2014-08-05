(function () {

    var isZipPath = function (path) {
      return (path.indexOf('/!') != -1);
    };

    var splitZipPath = function (path) {
      var parts = path.split('/!');
      if (parts.length != 2) {
        throw new Error("For now, you must have exactly one '/!' in your path when indexing into .zip files");
      }
      var zipPath = parts[0];
      var entryPath = parts[1];
      return { zipPath: zipPath, entryPath: entryPath };
    };


    fs.___original___readFileSync = fs.readFileSync;

    fs.readFileSync = function (path, options) {
      if (!options) {
        options = { encoding: null, flag: 'r' };
      } else if (util.isString(options)) {
        options = { encoding: options, flag: 'r' };
      } else if (!util.isObject(options)) {
        throw new TypeError('Bad arguments');
      }

      var encoding = options.encoding;
      assertEncoding(encoding);

      var flag = options.flag || 'r';

      if (encoding && ((encoding.toLowerCase() == 'utf8') || (encoding.toLowerCase() == 'utf-8')) && (flag == 'r')) {
        return binding.___CoreNode___readFileSyncUTF8(path);
      }

      return fs.___original___readFileSync(path, options);
    }

    fs.___original___readFile = fs.readFile;

    fs.readFile = function (path, options, callback_) {
      var callback = maybeCallback(arguments[arguments.length - 1]);

      if (util.isFunction(options) || !options) {
        options = { encoding: null, flag: 'r' };
      } else if (util.isString(options)) {
        options = { encoding: options, flag: 'r' };
      } else if (!util.isObject(options)) {
        throw new TypeError('Bad arguments');
      }

      var encoding = options.encoding;
      assertEncoding(encoding);

      var flag = options.flag || 'r';

      if (encoding && ((encoding.toLowerCase() == 'utf8') || (encoding.toLowerCase() == 'utf-8')) && (flag == 'r')) {
        return binding.___CoreNode___readFileUTF8(path, callback);
      }

      return fs.___original___readFile(path, options, callback_);

    }

    fs.___withoutZip___readFileSync = fs.readFileSync

    fs.readFileSync = function (path, options) {

      if (!isZipPath(path)) {
        return fs.___withoutZip___readFileSync(path, options);
      }

      if (!options) {
        options = { encoding: null, flag: 'r' };
      } else if (util.isString(options)) {
        options = { encoding: options, flag: 'r' };
      } else if (!util.isObject(options)) {
        throw new TypeError('Bad arguments');
      }

      var encoding = options.encoding;
      assertEncoding(encoding);

      var flag = options.flag || 'r';

      if (encoding && ((encoding.toLowerCase() == 'utf8') || (encoding.toLowerCase() == 'utf-8')) && (flag == 'r')) {
        var ze = splitZipPath(path);
        return binding.___CoreNode___readZipSyncUTF8(ze.zipPath, ze.entryPath);
      }

      throw new Error("/! shorthand for indexing into zip files only works with UTF-8 encoding file reading");

    }

    fs.___withoutZip___statSync = fs.statSync;
    fs.___withoutZip___lstatSync = fs.lstatSync;

    fs.statSync = function (path) {
      if (isZipPath(path)) {
        return binding.stat(path);
      } else {
        return fs.___withoutZip___statSync(path);
      }
    };

    fs.lstatSync = function (path) {
      if (isZipPath(path)) {
        return binding.lstat(path);
      } else {
        return fs.___withoutZip___lstatSync(path);
      }
    };

})();
