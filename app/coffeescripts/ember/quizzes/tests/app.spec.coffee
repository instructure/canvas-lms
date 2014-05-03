define [
  './start_app',
  'ember',
  'ic-ajax'
], (startApp, Ember, ajax) ->

  App = null

  module 'Ember sanity test',
    setup: ->
      App = startApp()
    teardown: ->
      Ember.run App, 'destroy'

  test 'Ember is up and running', ->
    ok(true)
