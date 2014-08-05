/**
 * Creates the Timer constructor function.
 */
(function(NativeTimerWrap) {
  var kOnTimeout = 0;

  function invokeTimeoutHandler() {
    return this[kOnTimeout].apply(this, arguments);
  }

  function Timer() {
    this._nativeTimer = NativeTimerWrap.newTimer();
    this._nativeTimer.onTimeout = invokeTimeoutHandler.bind(this);
  }

  Timer.kOnTimeout = kOnTimeout;

  Timer.now = function() {
    return NativeTimerWrap.now();
  };

  Timer.prototype.close = function() {
    this._nativeTimer.close();
  };

  // Unreferencing a timer is meaningless in Core Node
  Timer.prototype.ref = function() {};
  Timer.prototype.unref = function() {};

  Timer.prototype.start = function(delay, period) {
    this._nativeTimer.start(delay, period);
    return 0;
  };

  Timer.prototype.stop = function() {
    this._nativeTimer.stop();
    return 0;
  };

  Timer.prototype.setRepeat = function(period) {
    this._nativeTimer.repeatPeriod = period;
  };

  Timer.prototype.getRepeat = function() {
    return this._nativeTimer.repeatPeriod;
  };

  Timer.prototype.again = function() {
    if (!this[kOnTimeout]) {
      return -22;  // -EINVAL
    }
    var repeatPeriod = this.getRepeat();
    if (repeatPeriod) {
      this.stop();
      this.start(repeatPeriod, repeatPeriod);
    }
    return 0;
  };

  return Timer;
})
