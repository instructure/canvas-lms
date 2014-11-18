define(function(require) {
  var DEBUG = window.DEBUG = {};

  require([ '../../core/delegate' ], function(app) {
    Object.defineProperty(DEBUG, 'layout', {
      get: function() { return app.__getLayout__(); }
    });
  });

  return {
    apiToken: 'pOYZSthwwejYP7779HtgLGlL6BFZXC72KwbMbD54gm4d5NOzBov6Hma6VHvf0pJy',
    submissionUrl: '/api/v1/courses/1/quizzes/67/submissions/1108',
    eventsUrl: '/api/v1/courses/1/quizzes/67/submissions/1108/events',
    questionsUrl: '/api/v1/courses/1/quizzes/67/questions',
  };
});
