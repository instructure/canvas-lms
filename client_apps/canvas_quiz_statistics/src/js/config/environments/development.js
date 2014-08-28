define(function(require) {
  var rawAjax = require('../../util/xhr_request');
  var Root = this;
  var DEBUG = {
  };

  DEBUG.expose = function(script, varName) {
    require([ script ], function(__script__) {
      DEBUG[varName] = __script__;
    });
  };

  require([ 'boot' ], function(app) {
    DEBUG.app = app;
    DEBUG.update = app.update;
  });

  DEBUG.expose('react', 'React');
  DEBUG.expose('util/round', 'round');
  DEBUG.expose('stores/statistics', 'statisticsStore');

  Root.DEBUG = DEBUG;
  Root.d = DEBUG;

  return {
    xhr: {
      timeout: 5000
    },

    ajax: rawAjax,

    // This assumes you have set up reverse proxying on /api/v1 to Canvas.
    //
    // See ./README.md for more info on overriding these to use fixtures.
    quizStatisticsUrl: '/api/v1/courses/1/quizzes/1/statistics',
    quizReportsUrl: '/api/v1/courses/1/quizzes/1/reports',

    onError: function(message) {
      throw new Error(message);
    }
  };
});
