define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
  '../environment_setup'
  '../test_redirection'
  '../test_title'
]
, (Ember, startApp, fixtures, env, testRedirection, testTitle) ->

  module "Quiz Moderate: Integration",

    setup: ->
      App = startApp()
      fixtures.create()

     teardown: ->
       Ember.run App, 'destroy'

  # something about quizSubmissions and users association is causing promises
  # to not resolve and cause issues with getting `then` to resolve correctly
  # TODO: determine why

  # testRedirection
  #   path: '/1/moderate'
  #   defaultRoute: 'quiz.moderate'
  #   redirectRoute: 'quiz.show'

  # testTitle
  #   path: '/',
  #   title: 'Alt practices test: Moderate'
