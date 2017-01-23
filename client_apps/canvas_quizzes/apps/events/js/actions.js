define((require) => {
  const Dispatcher = require('./core/dispatcher');
  const EventStore = require('./stores/events');
  const Actions = {};

  Actions.dismissNotification = function (key) {
    return Dispatcher.dispatch('notifications:dismiss', key).promise;
  };

  Actions.reloadEvents = function () {
    EventStore.load();
  };

  Actions.setActiveAttempt = function (attempt) {
    EventStore.setActiveAttempt(attempt);
  };

  return Actions;
});
