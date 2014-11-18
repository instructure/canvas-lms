define(function(require) {
  var Dispatcher = require('canvas_quizzes/core/dispatcher');
  var Actions = {};

  Actions.regenerateReport = function(id) {
    return Dispatcher.dispatch('quizReports:regenerate', id).promise;
  };

  Actions.abortReportGeneration = function(id) {
    return Dispatcher.dispatch('quizReports:abort', id).promise;
  };

  Actions.dismissNotification = function(key) {
    return Dispatcher.dispatch('notifications:dismiss', key).promise;
  };

  return Actions;
});