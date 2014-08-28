define(function(require) {
  var RSVP = require('rsvp');
  var singleton;
  var callbacks = {};
  var gActionIndex = 0;

  var Dispatcher = function() {
    return this;
  };

  Dispatcher.prototype.dispatch = function(action, params) {
    var service = RSVP.defer();
    var actionIndex = ++gActionIndex;
    var callback = callbacks[action];

    if (callback) {
      callback(params, service.resolve, service.reject);
    }
    else {
      console.assert(false, 'No action handler registered to:', action);
      service.reject('Unknown action "' + action + '"');
    }

    return {
      promise: service.promise,
      index: actionIndex
    };
  };

  Dispatcher.prototype.register = function(action, callback) {
    if (callbacks[action]) {
      throw new Error("A handler is already registered to '" + action + "'");
    }

    callbacks[action] = callback;
  };

  singleton = new Dispatcher();

  return singleton;
});