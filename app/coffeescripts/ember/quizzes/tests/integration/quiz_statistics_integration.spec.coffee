define [
  'ember'
  '../start_app'
  '../environment_setup'
  '../shared_ajax_fixtures'
  '../test_redirection'
  '../test_title'
], (Ember, startApp, env, fixtures, testRedirection, testTitle) ->
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
    store = App.__container__.lookup('store:main')
    route = App.__container__.lookup('route:quizStatistics')
    ok q = route.modelFor('quiz'), 'loads the quiz'
    equal q.get('quizReports.length'), 2, 'loads quiz reports'
    ok qs = route.modelFor('quizStatistics'), 'loads quiz statistics'
    equal store.all('questionStatistics').get('length'), 13, 'loads question statistics into the store'
    equal qs.get('questionStatistics.length'), 13, 'associates question statistics'

  testRedirection
    path: '/1/statistics'
    defaultRoute: 'quiz.statistics'
    redirectRoute: 'quiz.show'

  test 'it shows up empty if there are no submissions', ->
    env.setUserPermissions(true, true)
    visit('/3/statistics').then ->
      equal find('.erratic-statistics').length, 1

  testPage 'it pre-activates an answer set for questions that have it', ->
    visit('/1/statistics').then ->
      equal find('.answer-set-tabs:first button:first.active').length, 1

  # TODO: cover the case of answer-set pre-activation where the question has
  # no answer sets, it should not blow up
  #
  # PENDING CNVS-14467
