define [
  'ember'
  '../start_app'
  '../environment_setup'
  '../shared_ajax_fixtures'
  '../../adapters/progress_adapter'
], (Ember, startApp, env, fixtures, Subject) ->
  App = null
  subject = null

  module 'Quiz Report Adapter',
    setup: ->
      App = startApp()
      fixtures.create()
      subject = App.__container__.lookup('adapter:progress')

     teardown: ->
       Ember.run App, 'destroy'

  test 'it builds the proper URL', ->
    strictEqual subject.buildURL('progress', 1), '/api/v1/progress/1'