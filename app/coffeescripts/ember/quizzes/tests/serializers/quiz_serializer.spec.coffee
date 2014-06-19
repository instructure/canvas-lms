define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  quizSerializer = null
  {run} = Ember
  store = null
  App = null

  module "QuizSerializer",
    setup: ->
      fixtures.create()
      App = startApp()
      run ->
        store = App.__container__.lookup 'store:main'

    teardown: ->
      run -> App.destroy()

  asyncTest "can fix assignment_overrides in extractArray", ->
    run ->
      store.find('quiz', 1).then (quiz) ->
        start()
        ok quiz.get('assignmentOverrides.length') > 0
