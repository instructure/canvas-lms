define(function(require) {
  var Store = require('../core/store');
  var Adapter = require('../core/adapter');
  var config = require('../config');
  var K = require('../constants');
  var RSVP = require('rsvp');
  var QuizReports = require('../collections/quiz_reports');
  var QuizStats = require('../collections/quiz_statistics');
  var onError = config.onError;
  var quizReports = new QuizReports();
  var quizStats = new QuizStats([]);

  var store = new Store('statistics', {
    /**
     * Load quiz statistics and reports.
     * Requires config.quizStatisticsUrl to be set.
     *
     * @async
     * @emit change
     */
    load: function() {
      var stats, reports;

      if (!config.quizStatisticsUrl) {
        return onError('Missing configuration parameter "quizStatisticsUrl".');
      }
      else if (!config.quizReportsUrl) {
        return onError('Missing configuration parameter "quizReportsUrl".');
      }

      stats = Adapter.request({
        type: 'GET',
        url: config.quizStatisticsUrl
      }).then(function(quizStatisticsPayload) {
        quizStats.reset(quizStatisticsPayload, { parse: true });
      });

      reports = Adapter.request({
        type: 'GET',
        url: config.quizReportsUrl
      }).then(function(quizReportsPayload) {
        quizReports.add(quizReportsPayload, { parse: true });
      });

      return RSVP.all([ stats, reports ]).then(function() {
        store.emitChange();
      });
    },

    getQuizStatistics: function() {
      if (quizStats.length) {
        return quizStats.first().toJSON();
      }
    },

    getSubmissionStatistics: function() {
      if (quizStats.length) {
        return quizStats.first().get('submissionStatistics');
      }
    },

    getQuestionStatistics: function() {
      if (quizStats.length) {
        return quizStats.first().get('questionStatistics');
      }
    },

    getQuizReports: function() {
      return quizReports.toJSON();
    },

    actions: {
      generateReport: function(reportType, onChange, onError) {
        Adapter.request({
          type: 'POST',
          url: config.quizReportsUrl,
          data: {
            quiz_reports: [{
              report_type: reportType,
              includes_all_versions: true
            }],
            include: ['progress', 'file']
          }
        }).then(function(quizReportsPayload) {
          quizReports.add(quizReportsPayload, { parse: true });
          onChange();
        }, onError);
      }
    },

    __reset__: function() {
      quizStats.reset();
      quizReports.reset();
      return Store.prototype.__reset__.call(this);
    }
  });

  return store;
});