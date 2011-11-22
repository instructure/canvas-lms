(function() {
  /*
  js!requires:
    - vendor/jquery-1.6.4.js
    - jQuery.ajaxJSON
  */
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  define('compiled/util/BackoffPoller', function() {
    var BackoffPoller;
    return BackoffPoller = (function() {
      function BackoffPoller(url, handler, opts) {
        var _ref, _ref2, _ref3;
        this.url = url;
        this.handler = handler;
        if (opts == null) {
          opts = {};
        }
        this.baseInterval = (_ref = opts.baseInterval) != null ? _ref : 1000;
        this.backoffFactor = (_ref2 = opts.backoffFactor) != null ? _ref2 : 1.5;
        this.maxAttempts = (_ref3 = opts.maxAttempts) != null ? _ref3 : 8;
      }
      BackoffPoller.prototype.start = function() {
        if (this.running) {
          this.reset();
        } else {
          this.nextPoll(true);
        }
        return this;
      };
      BackoffPoller.prototype['then'] = function(callback) {
        var _ref;
        if ((_ref = this.callbacks) == null) {
          this.callbacks = [];
        }
        return this.callbacks.push(callback);
      };
      BackoffPoller.prototype.reset = function() {
        this.nextInterval = this.baseInterval;
        return this.attempts = 0;
      };
      BackoffPoller.prototype.stop = function(success) {
        var callback, _i, _len, _ref;
        if (success == null) {
          success = false;
        }
        if (this.running) {
          clearTimeout(this.running);
        }
        delete this.running;
        if (success && this.callbacks) {
          _ref = this.callbacks;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            callback = _ref[_i];
            callback();
          }
        }
        return delete this.callbacks;
      };
      BackoffPoller.prototype.poll = function() {
        this.running = true;
        this.attempts++;
        return jQuery.ajaxJSON(this.url, 'GET', {}, __bind(function(data) {
          switch (this.handler(data)) {
            case 'continue':
              return this.nextPoll();
            case 'reset':
              return this.nextPoll(true);
            case 'stop':
              return this.stop(true);
            default:
              return this.stop();
          }
        }, this), __bind(function(data) {
          return this.stop();
        }, this));
      };
      BackoffPoller.prototype.nextPoll = function(reset) {
        if (reset == null) {
          reset = false;
        }
        if (reset) {
          this.reset();
        } else {
          this.nextInterval = parseInt(this.nextInterval * this.backoffFactor);
        }
        if (this.attempts > this.maxAttempts) {
          return this.stop();
        }
        return this.running = setTimeout(jQuery.proxy(this.poll, this), this.nextInterval);
      };
      return BackoffPoller;
    })();
  });
}).call(this);
