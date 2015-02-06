define(function(require) {
  var $ = require('canvas_packages/jquery');

  return {
    xhr: {
      timeout: 5000
    },

    pollingFrequency: 500,

    ajax: $.ajax,

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
