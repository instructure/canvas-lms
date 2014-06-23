define [
  'ember'
  '../start_app'
  '../environment_setup'
  '../shared_ajax_fixtures'
  '../../adapters/quiz_report_adapter'
], (Ember, startApp, env, fixtures, Subject) ->
  App = null
  subject = null

  module 'Quiz Report Adapter',
    setup: ->
      App = startApp()
      fixtures.create()
      subject = App.__container__.lookup('adapter:quizReport')

      #tmp workaround. these tests shouldn't need to visit the route
      env.setUserPermissions(true, true)
      visit('/1/statistics')

     teardown: ->
       Ember.run App, 'destroy'

  test 'it uses the report URL', ->
    url = subject.buildURL 'quizReport', 14
    ok url.match('/api/v1/courses/1/quizzes/1/reports/14')
