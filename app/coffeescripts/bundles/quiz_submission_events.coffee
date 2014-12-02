require [ 'jquery', 'canvas_quizzes/apps/events' ], ($, app) ->
  app.configure({
    ajax: $.ajax,
    loadOnStartup: true,
    quizUrl: ENV.quiz_url,
    questionsUrl: ENV.questions_url,
    submissionUrl: ENV.submission_url,
    eventsUrl: ENV.events_url,
    allowMatrixView: ENV.can_view_answer_audits
  });

  app.mount(document.body.querySelector('#content')).then ->
    console.log('Yeah, a canvas quiz app has been loaded!!!')
, (error) ->
  console.warn('App loading failed:', error, error.stack);

