define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
  '../environment_setup'
  'ic-ajax'
  'jquery'
  '../test_title'
  'jqueryui/dialog'
], (Ember, startApp, fixtures, env, ajax, $, testTitle) ->
  App = null

  QUIZ = fixtures.QUIZZES[0]
  ASSIGNMENT_GROUP = {fixtures}
  store = null

  module "Quiz Show Integration for Teachers",
    setup: ->
      App = startApp()
      fixtures.create()
      store = App.__container__.lookup('store:main')

     teardown: ->
       Ember.run App, 'destroy'

  testShowPage = (desc, callback) ->
    test desc, ->
      visit('/1').then callback

  testTitle
    path: '/1',
    title: 'Alt practice test: Overview'

  testShowPage 'shows attributes', ->
    html = find('#quiz-show').html()

    htmlHas = (matchingHTML, desc) ->
      ok html.match(matchingHTML), "shows #{desc}"

    ok html.indexOf(QUIZ.description) != -1, "doesn't escape server-sanitized HTML"
    htmlHas QUIZ.title, "quiz title"
    htmlHas QUIZ.points_possible, "points possible"

  testShowPage 'shows assignment group', ->
    text = find('#quiz-show').text()
    ok text.match ASSIGNMENT_GROUP.name

  testShowPage 'show page shows submission html', ->
    text = find('#quiz-show').text()
    ok text.match 'submission html!'

  testShowPage 'allows user to delete a quiz', ->
    quiz = null

    click('ic-menu-trigger').then ->
      click('ic-menu-item.js-delete')
    .then ->
      stop()
      store.find('quiz', 1).then (_quiz) ->
        quiz = _quiz
    .then ->
      start()
      ajax.defineFixture '/api/v1/courses/1/quizzes/1',
        response: {}
        jqXHR:
          statusCode: 204
        textStatus: 'success'
      click($ '.confirm-dialog-confirm-btn')
    .then ->
      ok quiz.get('isDeleted'), 'quiz deleted'

  testShowPage 'allows locking/unlocking from the dropdown menu', ->

    quiz = null
    lockAt = null

    clickLockUnlockToggler = ->
      click('ic-menu-trigger').then ->
        click('ic-menu-item.js-due-date-toggler')

    stop()
    store.find('quiz', 1).then (_quiz) ->
      quiz = _quiz
      lockAt = quiz.get 'lockAt'
      start()
    clickLockUnlockToggler().then ->
      ok quiz.get('lockAt') != lockAt, 'lock date updated'
    .then ->
      clickLockUnlockToggler()
    .then ->
      ok !quiz.get('lockAt'), 'can unlock quiz'

  testShowPage 'allows sending messages to students', ->
    server = sinon.fakeServer.create()
    server.respondWith 'POST',
      'http://localhost:3000/courses/1/quizzes/1/submission_users/message',
      JSON.stringify status: 'created'
    server.autoRespond = true
    click('ic-menu-trigger').then ->
      click '.js-message-students'
    .then ->
      fillIn '#message-body', 'Ohi'
      sinon.spy($, 'ajax')
    .then ->
      click '.ui-dialog .btn.btn-primary'
    .then ->
      firstCall = $.ajax.getCall(0).args[0]
      {url} = firstCall
      equal url, "http://localhost:3000/courses/1/quizzes/1/submission_users/message"
      server.restore()
      $.ajax.restore()

  testShowPage 'shows a link to take the quiz in the dropdown', ->
    click('ic-menu-trigger').then ->
      stop()
      store.find('quiz', 1)
    .then (quiz) ->
      start()
      equal $(find('.js-take-quiz')).attr('href'), quiz.get('takeQuizUrl')

  module "Quiz Show Integration for Students",
    setup: ->
      App = startApp()
      store = App.__container__.lookup('store:main')

     teardown: ->
       Ember.run App, 'destroy'

  testShowPage = (desc, callback) ->
    test desc, ->
      visit('/2').then callback

  testShowPage 'show page shows submission html', ->
    text = find('#quiz-show').text()
    ok text.match 'submission html!'

  testShowPage 'shows attributes', ->
    html = find('#quiz-show').html()

    htmlHas = (matchingHTML, desc) ->
      ok html.match(matchingHTML), "shows #{desc}"

    ok html.indexOf(QUIZ.description) != -1, "doesn't escape server-sanitized HTML"
    htmlHas QUIZ.title, "quiz title"
    htmlHas QUIZ.points_possible, "points possible"

  testShowPage 'doesnt show teacher actions', ->
    ok !find('.teacher-action-buttons').length, "shoudln't show teacher action buttons"

  testShowPage 'shows student actions', ->
    ok find('.student-action-buttons').length, "shoud show student action buttons"

  testShowPage 'doesnt show tabs', ->
    ok !find('#quiz-show-tabs').length, "should not have tabs"
