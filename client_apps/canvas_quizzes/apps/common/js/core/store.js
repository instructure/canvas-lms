define((require) => {
  const _ = require('lodash');
  const extend = _.extend;

  const Store = function (key, proto, Dispatcher) {
    const emitChange = this.emitChange.bind(this);

    extend(this, proto || {});

    this._key = key;
    this.__reset__();

    Object.keys(this.actions).forEach((action) => {
      const handler = this.actions[action].bind(this);
      const scopedAction = [key, action].join(':');

      // console.debug('Store action:', scopedAction);

      Dispatcher.register(scopedAction, (params, resolve, reject) => {
        try {
          handler(params, (rc) => {
            resolve(rc);
            emitChange();
          }, reject);
        } catch (e) {
          reject(e);
        }
      });
    });

    return this;
  };

  extend(Store.prototype, {
    actions: {},
    addChangeListener (callback) {
      this._callbacks.push(callback);
    },

    removeChangeListener (callback) {
      const index = this._callbacks.indexOf(callback);
      if (index > -1) {
        this._callbacks.splice(index, 1);
      }
    },

    emitChange () {
      this._callbacks.forEach((callback) => {
        callback();
      });
    },

    /**
     * @private
     *
     * A hook for tests to reset the Store to its initial state. Override this
     * to restore any side-effects.
     *
     * Usually during the life-time of the app, we will never have to reset a
     * Store, but in tests we do.
     */
    __reset__ () {
      this._callbacks = [];
      this.state = this.getInitialState();
    },

    getInitialState () {
      return {};
    },

    setState (newState) {
      extend(this.state, newState);
      this.emitChange();
    }
  });

  return Store;
});
