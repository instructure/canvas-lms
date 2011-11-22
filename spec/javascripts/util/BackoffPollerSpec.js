(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  define(['compiled/util/BackoffPoller'], function(BackoffPoller) {
    module('BackoffPoller', {
      setup: function() {
        this.ran_callback = false;
        return this.callback = __bind(function() {
          return this.ran_callback = true;
        }, this);
      }
    });
    asyncTest('should keep polling when it gets a "continue"', function() {
      var poller;
      poller = new BackoffPoller('fixtures/ok.json', function() {
        return 'continue';
      }, {
        backoffFactor: 1,
        baseInterval: 10,
        maxAttempts: 100
      });
      poller.start().then(this.callback);
      return setTimeout(__bind(function() {
        ok(poller.running, "poller should be running");
        poller.stop(false);
        return start();
      }, this), 100);
    });
    asyncTest('should reset polling when it gets a "reset"', function() {
      var poller;
      poller = new BackoffPoller('fixtures/ok.json', function() {
        return 'reset';
      }, {
        backoffFactor: 1,
        baseInterval: 10,
        maxAttempts: 100
      });
      poller.start().then(this.callback);
      return setTimeout(__bind(function() {
        ok(poller.running, "poller should be running");
        ok(poller.attempts <= 1, "counter should be reset");
        poller.stop(false);
        return start();
      }, this), 100);
    });
    asyncTest('should stop polling when it gets a "stop"', function() {
      var count, poller;
      count = 0;
      poller = new BackoffPoller('fixtures/ok.json', function() {
        if (count++ > 3) {
          return 'stop';
        } else {
          return 'continue';
        }
      }, {
        backoffFactor: 1,
        baseInterval: 10
      });
      poller.start().then(this.callback);
      return setTimeout(__bind(function() {
        ok(!poller.running, "poller should be stopped");
        ok(this.ran_callback, "poller should have run callbacks");
        return start();
      }, this), 100);
    });
    asyncTest('should abort polling when it hits maxAttempts', function() {
      var poller;
      poller = new BackoffPoller('fixtures/ok.json', function() {
        return 'continue';
      }, {
        backoffFactor: 1,
        baseInterval: 10,
        maxAttempts: 3
      });
      poller.start().then(this.callback);
      return setTimeout(__bind(function() {
        ok(!poller.running, "poller should be stopped");
        ok(!this.ran_callback, "poller should not have run callbacks");
        return start();
      }, this), 100);
    });
    return asyncTest('should abort polling when it gets anything else', function() {
      var count, poller;
      count = 0;
      poller = new BackoffPoller('fixtures/ok.json', function() {
        return 'omgwtfbbq';
      }, {
        baseInterval: 10
      });
      poller.start().then(this.callback);
      return setTimeout(__bind(function() {
        ok(!poller.running, "poller should be stopped");
        ok(!this.ran_callback, "poller should not have run callbacks");
        return start();
      }, this), 100);
    });
  });
}).call(this);
