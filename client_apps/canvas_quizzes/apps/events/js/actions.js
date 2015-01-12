define(function(require) {
  var Dispatcher = require('canvas_quizzes/core/dispatcher');
  var EventStore = require('./stores/events');
  var Actions = {};

  Actions.dismissNotification = function(key) {
    return Dispatcher.dispatch('notifications:dismiss', key).promise;
  };

  Actions.reloadEvents = function() {
    EventStore.load();
  };

  Actions.setActiveAttempt = function(attempt) {
    EventStore.setActiveAttempt(attempt);
  };

  return Actions;
});