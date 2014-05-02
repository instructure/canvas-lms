define [
  'ember'
  '../start_app'
  '../environment_setup'
  '../shared_ajax_fixtures'
  '../test_redirection'
], (Ember, startApp, env, fixtures, testRedirection) ->
  App = null

  {$} = Ember

  module "Quiz Statistics Integration",
    setup: ->
      App = startApp()
      fixtures.create()

     teardown: ->
       Ember.run App, 'destroy'

  testPage = (desc, callback) ->
    test desc, ->
      env.setUserPermissions(true, true)
      visit('/1/statistics').then callback

  testPage 'it renders', ->
    equal find('#quiz-statistics').length, 1

  testPage 'it loads the quiz, statistics, and question statistics', ->
    route = App.__container__.lookup('route:quizStatistics')
    ok q = route.modelFor('quiz'), 'loads the quiz'
    equal q.get('quizReports.length'), 2, 'loads quiz reports'
    ok qs = route.modelFor('quizStatistics'), 'loads quiz statistics'
    equal qs.get('questionStatistics.length'), 11, 'loads question statistics'

  testRedirection
    path: '/1/statistics'
    defaultRoute: 'quiz.statistics'
    redirectRoute: 'quiz.show'
