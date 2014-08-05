(function(process) {
  var nodeVersion = '0.11.11';

  process.title = 'node';
  process.version = 'v' + nodeVersion;
  process.versions.node = nodeVersion;
  process.versions.modules = '11';
  process.moduleLoadList = [];
  process.platform = 'darwin';
  process.execArgv = [];
  process.features = {};
  process._events = {};

  var nativeChdir = process.chdir.bind(process);
  process.chdir = function chdir(path) {
    if (typeof path !== 'string') {
      throw new TypeError('chdir expects a string path');
    }
    nativeChdir(path);
  };

  var nativeUmask = process.umask.bind(process);
  process.umask = function(mask) {
    if (mask === undefined) {
      mask = 0;
    } else if (typeof mask === 'string') {
      mask = Number.parseInt(mask, 8);
    } else if (typeof mask !== 'number') {
      throw new TypeError('file mask must be an integer or octal string');
    }
    return nativeUmask(mask);
  };

  var nativeSetUid = process.setuid.bind(process);
  process.setuid = function setuid(uid) {
    var type = typeof uid;
    if (type !== 'number' && type !== 'string') {
      throw new TypeError('setuid argument must be a number or a string');
    }
    nativeSetUid(uid);
  };

  var nativeSetupAsyncListener = process._setupAsyncListener.bind(process);
  process._setupAsyncListener = function(
    flags,
    runHandler,
    loadHandler,
    unloadHandler
  ) {
    nativeSetupAsyncListener(flags, runHandler, loadHandler, unloadHandler);
    delete process._setupAsyncListener;
  }

  var nativeSetupNextTick = process._setupNextTick.bind(process);
  process._setupNextTick = function(tickInfo, tickHandler) {
    if (!tickInfo || typeof tickInfo !== 'object') {
      throw new TypeError('tick info must be an object');
    }
    if (typeof tickHandler !== 'function') {
      throw new TypeError('tick callback must be a function');
    }
    nativeSetupNextTick(tickInfo, tickHandler);
    delete process._setupNextTick;
  };

  var nativeSetupDomainUse = process._setupDomainUse.bind(process);
  process._setupDomainUse = function(domainArray, domainFlags) {
    if (typeof process._tickDomainCallback !== 'function') {
      throw new TypeError('process._tickDomainCallback assigned to non-function');
    }
    if (!Array.isArray(domainArray)) {
      throw new TypeError('domain array must be an array');
    }
    if (!domainFlags || typeof domainFlags !== 'object') {
      throw new TypeError('domain flags must be an object');
    }

    nativeSetupDomainUse(domainArray, domainFlags);
    delete process._setupDomainUse;
  }

  return process;
})
