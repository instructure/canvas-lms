define(function(require) {
  var Dispatcher = require('./core/dispatcher');
  var Actions = {};

  Actions.dismissNotification = function(key) {
    return Dispatcher.dispatch('notifications:dismiss', key).promise;
  };

  return Actions;
});