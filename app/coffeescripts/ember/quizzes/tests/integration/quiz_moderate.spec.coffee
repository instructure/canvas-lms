define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
  '../environment_setup'
  '../test_redirection'
]
, (Ember, startApp, fixtures, env, testRedirection) ->

  module "Quiz Moderate: Integration",

    setup: ->
      App = startApp()
      fixtures.create()

     teardown: ->
       Ember.run App, 'destroy'

  # something about quizSubmissions and users association isn't resolving
  # and cause instability in this
  # TODO: determine why
  # testRedirection
  #   path: '/1/moderate'
  #   defaultRoute: 'quiz.moderate'
  #   redirectRoute: 'quiz.show'
