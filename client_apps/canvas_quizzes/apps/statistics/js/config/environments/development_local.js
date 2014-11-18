define(function(require) {
  var StatisticsStore = require('app/stores/statistics');
  var rawAjax = require('canvas_quizzes/util/xhr_request');

  DEBUG.expose('app/stores/statistics', 'statisticsStore');
  DEBUG.expose('app/stores/reports', 'reportStore');
  // DEBUG.expose('stores/notifications', 'notificationStore');
  // DEBUG.expose('actions', 'actions');

  require([ 'app/core/delegate' ], function(app) {
    Object.defineProperty(DEBUG, 'layout', {
      get: function() { return app.__getLayout__(); }
    });
  });

  require([ '../../main' ], function(app) {
    DEBUG.app = app;
    DEBUG.update = app.update;
  });

  DEBUG.tickProgressBar = function() {
    var completion = 0;
    var interval = 1000;
    var quizReports = StatisticsStore.getQuizReports();

    var tick = setInterval(function() {
      var step = (Math.ceil((Math.random() * 100)) % 10) + 1;
      completion += step;

      quizReports.forEach(function(report) {
        if (report.generatable) {
          report.progress = report.progress || {};
          report.progress.workflowState = 'running';
          report.progress.completion = completion;
        }
      });

      DEBUG.update({
        quizReports: quizReports
      });

      if (completion >= 100) {
        return clearInterval(tick);
      }
    }, interval)
  };

  DEBUG.randomizeScores = function(randomizer) {
    randomizer = randomizer || 25;

    var newScores = _
      .range(101)
      .map(function(i) { return _.random(0, randomizer); })
      .reduce(function(points, point, i) {
        points[i] = point; return points;
      }, {});

    require([ 'lodash', 'stores/statistics', 'core/delegate' ], function(_, store, app) {
      var stats = store.get();
      stats.submissionStatistics.scores = newScores;

      app.update({ quizStatistics: stats });
    });
  };

  DEBUG.switchQuiz = function(quizId) {
    require([ 'core/delegate' ], function(app) {
      app.configure({
        quizStatisticsUrl: '/api/v1/courses/1/quizzes/' + quizId + '/statistics',
        quizReportsUrl: '/api/v1/courses/1/quizzes/' + quizId + '/reports'
      });

      app.reload();
    });
  };

  return {
    // ajax: rawAjax,

    apiToken: 'pOYZSthwwejYP7779HtgLGlL6BFZXC72KwbMbD54gm4d5NOzBov6Hma6VHvf0pJy',
    quizStatisticsUrl: '/api/v1/courses/1/quizzes/8/statistics',
    quizReportsUrl: '/api/v1/courses/1/quizzes/8/reports',
    // quizStatisticsUrl: '/fixtures/quiz_statistics_single_submission.json',
    // quizStatisticsUrl: '/fixtures/quiz_statistics_large_question.json',
    // quizStatisticsUrl: '/fixtures/quiz_statistics_all_types.json',
    // quizReportsUrl: '/fixtures/quiz_reports.json',
    pollingFrequency: 1000,

    // loadOnStartup: false
    // fakeXHRDelay: 2500
  };
});
