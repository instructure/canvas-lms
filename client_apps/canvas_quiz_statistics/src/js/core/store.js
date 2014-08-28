define(function(require) {
  var _ = require('lodash');
  var Dispatcher = require('./dispatcher');
  var extend = _.extend;

  var Store = function(key, proto) {
    var emitChange = this.emitChange.bind(this);

    this._key = key;
    this.__reset__();

    extend(this, proto || {});

    Object.keys(this.actions).forEach(function(action) {
      var handler = this.actions[action].bind(this);
      var scopedAction = [ key, action ].join(':');

      console.debug('Store action:', scopedAction);

      Dispatcher.register(scopedAction, function(params, resolve, reject) {
        try {
          handler(params, function onChange(rc) {
            resolve(rc);
            emitChange();
          }, reject);
        } catch(e) {
          reject(e);
        }
      });

    }.bind(this));

    return this;
  };

  extend(Store.prototype, {
    actions: {},
    addChangeListener: function(callback) {
      this._callbacks.push(callback);
    },

    removeChangeListener: function(callback) {
      var index = this._callbacks.indexOf(callback);
      if (index > -1) {
        this._callbacks.splice(index, 1);
      }
    },

    emitChange: function() {
      this._callbacks.forEach(function(callback) {
        callback();
      });
    },

    /**
     * @internal
     * A hook for tests to reset the Store to its initial state. Override this
     * to restore any side-effects.
     *
     * Usually during the life-time of the app, we will never have to reset a
     * Store, but in tests we do.
     */
    __reset__: function() {
      this._callbacks = [];
    }
  });

  return Store;
});