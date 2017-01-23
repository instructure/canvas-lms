define((require) => {
  const Store = require('canvas_quizzes/core/store');
  const Dispatcher = require('../core/dispatcher');
  const _ = require('lodash');
  const throttle = _.throttle;


  /**
   * @class Stores.Notifications
   *
   * Display "stateful" and "one-time" alerts and notices.
   */
  const store = new Store('notifications', {
    _state: {
      notifiers: [],
      notifications: [],
      dismissed: [],
      watchedTargets: []
    },

    initialize () {
      this.run = throttle(this.run.bind(this), 100, {
        leading: false,
        trailing: true
      });
    },

    registerWatcher (notifier) {
      const watchTargets = notifier.watchTargets || [];
      const watchedTargets = this._state.watchedTargets;
      const run = this.run.bind(this);

      watchTargets.filter(target => watchedTargets.indexOf(target) === -1).forEach((target) => {
        target.addChangeListener(run);
      });

      this._state.notifiers.push(notifier);
    },

    /**
     * @return {Models.Notification[]}
     *         All available notifications. Notifications that were dismissed
     *         by the user will not be returned.
     */
    getAll () {
      const dismissed = this._state.dismissed;

      return this._state.notifications.filter(notification => dismissed.indexOf(notification.id) === -1).map(notification => notification.toJSON());
    },

    run () {
      this._state.notifications =
        this._state.notifiers.reduce((notifications, notifier) => notifications.concat(notifier()), []);

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
      dismiss (id, onChange/* , onError*/) {
        const dismissed = this._state.dismissed;

        if (dismissed.indexOf(id) === -1) {
          dismissed.push(id);
          onChange();
        }
      }
    }
  }, Dispatcher);

  return store;
});
