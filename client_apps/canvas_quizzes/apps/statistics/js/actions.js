define((require) => {
  const Dispatcher = require('./core/dispatcher');
  const Actions = {};

  Actions.regenerateReport = function (id) {
    return Dispatcher.dispatch('quizReports:regenerate', id).promise;
  };

  Actions.abortReportGeneration = function (id) {
    return Dispatcher.dispatch('quizReports:abort', id).promise;
  };

  Actions.dismissNotification = function (key) {
    return Dispatcher.dispatch('notifications:dismiss', key).promise;
  };

  return Actions;
});
