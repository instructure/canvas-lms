define((require) => {
  const RSVP = require('rsvp');
  let singleton;
  const callbacks = {};
  let gActionIndex = 0;

  const Dispatcher = function (inputConfig) {
    this.config = inputConfig;
  };

  Dispatcher.prototype.dispatch = function (action, params) {
    const service = RSVP.defer();
    const actionIndex = ++gActionIndex;
    const callback = callbacks[action];

    if (callback) {
      callback(params, service.resolve, service.reject);
    } else {
      console.assert(false, 'No action handler registered to:', action);
      this.config.onError('No action handler registered to:', action);
      service.reject(`Unknown action "${action}"`);
    }

    return {
      promise: service.promise,
      index: actionIndex
    };
  };

  Dispatcher.prototype.register = function (action, callback) {
    if (callbacks[action]) {
      throw new Error(`A handler is already registered to '${action}'`);
    }

    callbacks[action] = callback;
  };

  return Dispatcher;
});
