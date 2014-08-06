require([ 'jquery', 'canvas_quiz_statistics' ], function($, app) {
  app.configure({
    ajax: $.ajax,
    loadOnStartup: true,
    quizStatisticsUrl: ENV.quiz_statistics_url,
    quizReportsUrl: ENV.quiz_reports_url
  });

  app.mount(document.body.querySelector('#content')).then(function() {
    console.log('Yeah!!!');
  });
}, function(error) {
  console.warn('CQS loading failed:', error, error.stack);
});

