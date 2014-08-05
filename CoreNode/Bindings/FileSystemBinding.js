// To be used in conjunction with FileSystemBindings.m/h
// maps to process.binding('fs')
(function (fromNative_) {

    // start experimental
     function insertAndExecute(id, text) {
      domelement = document.getElementById(id);
      domelement.innerHTML = text;
      var scripts = [];

      ret = domelement.childNodes;
      for ( var i = 0; ret[i]; i++ ) {
        if ( scripts && nodeName( ret[i], "script" ) && (!ret[i].type || ret[i].type.toLowerCase() === "text/javascript") ) {
          scripts.push( ret[i].parentNode ? ret[i].parentNode.removeChild( ret[i] ) : ret[i] );
        }
      }

      for(script in scripts) {
        evalScript(scripts[script]);
      }
    }

    function nodeName( elem, name ) {
      return elem.nodeName && elem.nodeName.toUpperCase() === name.toUpperCase();
    }

    function evalScript( elem ) {
      data = ( elem.text || elem.textContent || elem.innerHTML || "" );

      var head = document.getElementsByTagName("head")[0] || document.documentElement,
      script = document.createElement("script");
      script.type = "text/javascript";
      script.appendChild( document.createTextNode( data ) );
      head.insertBefore( script, head.firstChild );
      head.removeChild( script );

      if ( elem.parentNode ) {
        elem.parentNode.removeChild( elem );
      }
    }
    // end experimental

    var LOGGING = false;

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

    var statsForZip = function (archiveStat, entryStat) {
      //fromNative_.DDLog(JSON.stringify(Array.prototype.slice.call(arguments)));
      if (entryStat) {
        archiveStat.mtime = entryStat.lastModified;
        archiveStat.size = entryStat.uncompressedSize;
        archiveStat.mode = entryStat.fileMode;
        return archiveStat;
      } else {
        throw new Error("Could not find entry in zip");
      }
    }


    var fromNative;

    if (LOGGING) {
      fromNative = {};
      // Wrapper for logging stuff
      var __counts = {};
      var wrapper = function (f, name) {
        return function () {
          //fromNative_.DDLog(name + "(" + Array.prototype.slice.call(arguments).join(", ") + ")");
          if (name.indexOf("stat") != -1) {
          //if (true) {
            __counts[name] = __counts[name] && __counts[name] + 1 || 1;
            //fromNative_.DDLog(name + ": " + __counts[name]);
            fromNative_.DDLog(name + JSON.stringify(Array.prototype.slice.call(arguments)));
          }
          return f.apply(this, Array.prototype.slice.call(arguments));
        }
      }


      for (var prop in fromNative_) {
        if (prop != "DDLog") {
        //if (false) {
          fromNative[prop] = wrapper(fromNative_[prop], prop);
        } else {
          fromNative[prop] = fromNative_[prop];
        }
      }
    } else {
      fromNative = fromNative_;
    }

    var constants = process.binding('constants');

    // Argument checking helper functions
    var isString = function (obj) {
      return toString.call(obj) == '[object String]';
    };

    var isNumber = function (obj) {
      return toString.call(obj) == '[object Number]';
    };

    var isFunction = function (obj) {
      return typeof obj === 'function';
    };

    var _errorMakerWrapCallback = function (callback, text) {
      return function (err, result) {
        if (err) {
          var msg = err;
          if (text) {
            msg = "(" + err + ") " + text;
          }
          callback(new Error(msg), result);
        } else {
          callback(err, result);
        }
      };
    };

    var _throwIfError = function (err, text) {
      if (err) {
        throw new Error("Error (" + err + ") " + text);
      }
      return err;
    }

    return {
      FSInitialize: fromNative.FSInitialize.bind(fromNative),

      close: function (fd, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (isFunction(callback)) {
          // async
          return fromNative._close_async(fd, function (err, result) {
            if (err) {
              callback(new Error(err), result);
            } else {
              callback(err, result);
            }
          });
        } else {
          // sync
          return fromNative._close_sync(fd);
        }
      },

      open: function (path, flags, mode, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        if (!isNumber(flags)) {
          throw new TypeError("flags must be a number");
        }
        if (!isNumber(mode)) {
          throw new TypeError("mode must be a number");
        }

        if (isFunction(callback)) {
          // async
          return fromNative._open_async(path, flags, mode, function (err, result) {
            if (err) {
              callback(new Error(err), result);
            } else {
              callback(err, result);
            }
          });
        } else {
          // sync
          return fromNative._open_sync(path, flags, mode);
        }

      },

      read: function (fd, buf, offset, length, position, callback) {

        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }

        if (!Buffer.isBuffer(buf)) {
          throw new TypeError("buf must be a Buffer");
        }

        // Offset is allowed to be not a number, and then we use
        // -1 according to the node_file.cc source
        //   pos = GET_OFFSET(args[4]);
        // This seems odd though

        if (!isNumber(length)) {
          throw new TypeError("length must be a number");
        }

        var bufferLength = buf.length;

        if (offset >= bufferLength) {
          throw new Error("offset is out of bounds");
        }

        if (offset + length > bufferLength) {
          throw new Error("length extends beyond buffer");
        }

        var pos = -1;
        if (isNumber(position)) {
          pos = position;
        }

        var text = "Could not read file";

        if (isFunction(callback)) {
          return fromNative._read_async(fd, buf, offset, pos, length, _errorMakerWrapCallback(callback, text));
        } else {
          return fromNative._read_sync(fd, buf, offset, pos, length);
        }

      },

      fdatasync: function (fd, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }

        var text = "Could not fdatasync";

        if (isFunction(callback)) {
          // async
          return fromNative._fdatasync_async(fd, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._fdatasync_sync(fd), text);
        }

      },

      fsync: function (fd, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }

        var text = "Could not fsync";

        if (isFunction(callback)) {
          // async
          return fromNative._fsync_async(fd, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._fsync_sync(fd), text);
        }

      },

      rename: function (from, to, callback) {
        if (!isString(from)) {
          throw new TypeError("from must be a string");
        };
        if (!isString(to)) {
          throw new TypeError("to must be a string");
        };
        var text = "Could not rename";
        if (isFunction(callback)) {
          // async
          return fromNative._rename_async(from, to, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._rename_sync(from, to), text);
        }

      },

      ftruncate: function (fd, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        var text = "Could not ftruncate";
        if (isFunction(callback)) {
          // async
          return fromNative._ftruncate_async(fd, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._ftruncate_sync(fd), text);
        }
      },

      rmdir: function (path, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        var text = "Could not rmdir";

        if (isFunction(callback)) {
          // async
          return fromNative._rmdir_async(path, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._rmdir_sync(path), text);
        }
      },

      mkdir: function (path, mode, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        if (!isNumber(mode)) {
          throw new TypeError("mode must be a number");
        }
        var text = "Could not mkdir";
        if (isFunction(callback)) {
          return fromNative._mkdir_async(path, mode, _errorMakerWrapCallback(callback, text));
        } else {
          return fromNative._mkdir_sync(path, mode);
        }
      },

      readdir: function (path, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }

        var text = "Could not readdir";
        if (isFunction(callback)) {
          return fromNative._readdir_async(path, _errorMakerWrapCallback(callback, text));
        } else {
          return fromNative._readdir_sync(path);
        }
      },

      stat: function (path, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }

        if (isFunction(callback)) {

          // async
          return fromNative._stat_async(path, function (err, stats) {
              if (err) {
                callback(new Error(err), result);
              } else {
                callback(err, stats);
              }
            });

        } else {

          // sync
          if (isZipPath(path)) {
            var info = splitZipPath(path);
            var archiveStat = fromNative._stat_sync(info.zipPath);
            var entryStat = fromNative._zipstat_sync(info.zipPath, info.entryPath);
            return statsForZip(archiveStat, entryStat);
          } else {
            return fromNative._stat_sync(path);
          }

        }

      },

      lstat: function (path, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        if (isFunction(callback)) {
          // async
          return fromNative._lstat_async(path, function (err, result) {
            if (err) {
              callback(new Error(err), result);
            } else {
              callback(err, result);
            }
          });
        } else {
          // sync
          if (isZipPath(path)) {
            var info = splitZipPath(path);
            var archiveStat = fromNative._stat_sync(info.zipPath);
            var entryStat = fromNative._zipstat_sync(info.zipPath, info.entryPath);
            return statsForZip(archiveStat, entryStat);
          } else {
            return fromNative._lstat_sync(path);
          }
        }
      },

      fstat: function (fd, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (isFunction(callback)) {
          // async
          return fromNative._fstat_async(fd, function (err, result) {
            if (err) {
              callback(new Error(err), result);
            } else {
              callback(err, result);
            }
          });
        } else {
          // sync
          return fromNative._fstat_sync(fd);
        }
      },

      link: function (destPath, srcPath, callback) {
        if (!isString(destPath)) {
          throw new TypeError("destPath must be a string");
        }
        if (!isString(srcPath)) {
          throw new TypeError("srcPath must be a string");
        }
        if (isFunction(callback)) {
          // async
          return fromNative._link_async(destPath, srcPath, _errorMakerWrapCallback(callback, "Could not create link"));
        } else {
          // sync
          var err = fromNative._link_sync(destPath, srcPath);
          if (err) {
            throw new Error("(" + err + ") Could not create link");
          }
        }

      },

      symlink: function (destPath, srcPath, mode, callback) {
        var UV_FS_SYMLINK_DIR = 1;
        var UV_FS_SYMLINK_JUNCTION = 2;


        if (!isString(destPath)) {
          throw new TypeError("destPath must be a string");
        }

        if (!isString(srcPath)) {
          throw new TypeError("srcPath must be a string");
        }

        var flags = 0;
        // I think these modes only apply on NTFS (Windows), but
        // we'll accept the options for compatibility
        if (isString(mode)) {
          if (mode == "dir") {
            flags |= UV_FS_SYMLINK_DIR;
          } else if (mode == "junction") {
            flags |= UV_FS_SYMLINK_JUNCTION;
          } else if (mode != "file") {
            throw new TypeError("Unknown symlink type");
          }
        }

        if (isFunction(callback)) {
          return fromNative._symlink_async(destPath, srcPath, flags, _errorMakerWrapCallback(callback, "Could not create symlink"));
        } else {
          var err = fromNative._symlink_sync(destPath, srcPath, flags);
          if (err) {
            throw new Error("Error (" + err + ") Could not create symlink");
          }
        }

      },

      readlink: function (path, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        if (isFunction(callback)) {
          // async
          return fromNative._readlink_async(path, _errorMakerWrapCallback(callback, "Could not readlink"));
        } else {
          // sync
          return fromNative._readlink_sync(path);
        }
      },

      unlink: function (path, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        var text = "Could not unlink";
        if (isFunction(callback)) {
          // async
          return fromNative._unlink_async(path, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._unlink_sync(path), text);
        }
      },

      writeBuffer: function (fd, buffer, offset, length, position, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (!Buffer.isBuffer(buffer)) {
          throw new TypeError("buffer must be a Buffer");
        }
        if (!isNumber(length)) {
          throw new TypeError("length must be a number");
        }

        var bufferLength = buffer.length;

        if (offset > bufferLength) {
          throw new Error("offset out of bounds");
        }

        if (length > bufferLength) {
          throw new Error("length out of bounds");
        }

        if (offset + length < offset) {
          throw new Error("off + len overflow");
        }

        if (offset + length > buffer) {
          throw new Error("off + len > buffer.length");
        }

        var pos = -1;
        if (isNumber(position)) {
          pos = position;
        }

        if (isFunction(callback)) {
          // async
          return fromNative._write_async(fd, buffer, offset, length, pos, _errorMakerWrapCallback(callback, "Could not write file"));
        } else {
          // sync
          return fromNative._write_sync(fd, buffer, offset, length, pos);
        }

      },

      writeString: function (fd, string, position, enc, callback) {

        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (!isString(string)) {
          throw new TypeError("string must be a string");
        }
        var pos = -1;
        if (isNumber(position)) {
          pos = position;
        }
        if (!isString(enc)) {
          enc = "UTF8";
        }
        if (!Buffer.isEncoding(enc)) {
          throw new Error("enc must be a valid encoding (defaults to 'UTF8')");
        }

        enc = enc.toLowerCase();
        if (enc != "utf8" && enc != "utf-8") {
          throw new Error("Only UTF-8 is supported by writeString right now");
        }

        var pos = -1;
        if (isNumber(position)) {
          pos = position;
        }

        if (isFunction(callback)) {
          // async
          return fromNative._write_string_async(fd, string, pos, enc, _errorMakerWrapCallback(callback, "Could not write file"));
        } else {
          // sync
          return fromNative._write_string_sync(fd, string, pos, enc);
        }


        throw new Error("not implemented yet");

      },


      chmod: function (path, mode, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        if (!isNumber(mode)) {
          throw new TypeError("mode must be a number");
        }
        var text = "Could not chmod";
        if (isFunction(callback)) {
          return fromNative._chmod_async(path, mode, _errorMakerWrapCallback(callback, text));
        } else {
          _throwIfError(fromNative._chmod_sync(path, mode), text);
        }

      },

      fchmod: function (fd, mode, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (!isNumber(mode)) {
          throw new TypeError("mdoe must be a number");
        }
        var text = "Could not fchmod";
        if (isFunction(callback)) {
          return fromNative._fchmod_async(fd, mode, _errorMakerWrapCallback(callback, text));
        } else {
          _throwIfError(fromNative._fchmod_sync(fd, mode), text);
        }

      },

      chown: function (path, uid, gid, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        }
        if (!isNumber(uid)) {
          throw new TypeError("uid must be a number");
        }
        if (!isNumber(gid)) {
          throw new TypeError("gid must be a number");
        }

        var text = "Could not chown";
        if (isFunction(callback)) {
          return fromNative._chown_async(path, uid, gid, _errorMakerWrapCallback(callback, text));
        } else {
          _throwIfError(fromNative._chown_sync(path, uid, gid), text);
        }

      },


      fchown: function (fd, uid, gid, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (!isNumber(uid)) {
          throw new TypeError("uid must be a number");
        }
        if (!isNumber(gid)) {
          throw new TypeError("gid must be a number");
        }

        var text = "Could not fchown";
        if (isFunction(callback)) {
          return fromNative._fchown_async(fd, uid, gid, _errorMakerWrapCallback(callback, text));
        } else {
          _throwIfError(fromNative._fchown_sync(fd, uid, gid), text);
        }


      },

      utimes: function (path, atime, mtime, callback) {
        if (!isString(path)) {
          throw new TypeError("path must be a string");
        };
        if (!isNumber(atime)) {
          throw new TypeError("atime must be a number");
        }
        if (!isNumber(mtime)) {
          throw new TypeError("mtime must be a number");
        }

        var text = "Could not set utimes";
        if (isFunction(callback)) {
          // async
          return fromNative._utimes_async(path, atime, mtime, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._utimes_sync(path, atime, mtime), text);
        }

      },

      futimes: function (fd, atime, mtime, callback) {
        if (!isNumber(fd)) {
          throw new TypeError("fd must be a file descriptor (number)");
        }
        if (!isNumber(atime)) {
          throw new TypeError("atime must be a number");
        }
        if (!isNumber(mtime)) {
          throw new TypeError("mtime must be a number");
        }

        var text = "Could not set utimes using futimes";
        if (isFunction(callback)) {
          // async
          return fromNative._futimes_async(fd, atime, mtime, _errorMakerWrapCallback(callback, text));
        } else {
          // sync
          _throwIfError(fromNative._futimes_sync(fd, atime, mtime), text);
        }

      },

      ___CoreNode___readFileSyncUTF8: function (path) {
        try {
          return fromNative._readfile_utf8_sync(path);
        } catch (e) {
          throw new Error(e);
        }
      },

      ___CoreNode___readFileUTF8: function (path, callback) {
        return fromNative._readfile_utf8_async(path, _errorMakerWrapCallback(callback, "Could not readFile"));
      },

      // This function won't work unless the code at the top of this
      // file for logging/counting is uncommented
      //__counts__: function () { return __counts; },

      ___CoreNode___readZipSyncUTF8: function (zipPath, entryPath) {
        try {
          return fromNative._readzip_utf8_sync(zipPath, entryPath);
        } catch (e) {
          throw new Error(e);
        }
      },

      ___CoreNode___zipstat_sync: function (zipPath, entryPath) {
        return fromNative._zipstat_sync(zipPath, entryPath);
      },

      executeScriptFromURL: function (url) {
        //var domid = "tmp-" + Math.random().toString().substr(2);
        var head = document.getElementsByTagName("head")[0] || document.documentElement;
        var script = document.createElement('script');
        script.src = url;
        script.type = "text/javascript";
        //script.appendChild( document.createTextNode(code) );
        head.insertBefore(script, head.firstChild);

        // Clean up
        //script.parentNode.removeChild(script);
      },


      StatWatcher: function () {
        throw new Error("StatWatcher not implemented");
      },
      fromNative: fromNative,
    };
})
