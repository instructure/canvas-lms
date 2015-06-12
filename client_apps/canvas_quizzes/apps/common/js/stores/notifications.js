define(function(require) {
  var Store = require('../core/store');
  var _ = require('lodash');
  var throttle = _.throttle;

  /**
   * @class Stores.Notifications
   *
   * Display "stateful" and "one-time" alerts and notices.
   */
  var store = new Store('notifications', {
    _state: {
      notifiers: [],
      notifications: [],
      dismissed: [],
      watchedTargets: []
    },

    initialize: function() {
      this.run = throttle(this.run.bind(this), 100, {
        leading: false,
        trailing: true
      });
    },

    registerWatcher: function(notifier) {
      var watchTargets = notifier.watchTargets || [];
      var watchedTargets = this._state.watchedTargets;
      var run = this.run.bind(this);

      watchTargets.filter(function(target) {
        return watchedTargets.indexOf(target) === -1;
      }).forEach(function(target) {
        target.addChangeListener(run);
      });

      this._state.notifiers.push(notifier);
    },

    /**
     * @return {Models.Notification[]}
     *         All available notifications. Notifications that were dismissed
     *         by the user will not be returned.
     */
    getAll: function() {
      var dismissed = this._state.dismissed;

      return this._state.notifications.filter(function(notification) {
        return dismissed.indexOf(notification.id) === -1;
      }).map(function(notification) {
        return notification.toJSON();
      });
    },

    run: function() {
      this._state.notifications =
        this._state.notifiers.reduce(function(notifications, notifier) {
          return notifications.concat(notifier());
        }, []);

      this.emitChange();
    },

    actions: {
      /**
       * Dismiss a notification during the current session. Dismissals do not
       * currently persist through page refreshes.
       *
       * @param  {String} id
       *         The unique notification id.
       */
      dismiss: function(id, onChange/*, onError*/) {
        var dismissed = this._state.dismissed;

        if (dismissed.indexOf(id) === -1) {
          dismissed.push(id);
          onChange();
        }
      }
    }
  });

  return store;
});