define [
  './start_app'
  'ember'
  'ic-ajax'
], (startApp, Ember, ajax) ->

  App = null


  module 'student_groups',
    setup: ->
      App = startApp()
    teardown: ->
      Ember.run App, 'destroy'


  test 'Ember is running', ->
    ok(true)

