define [
  'ember'
  '../start_app'
  '../environment_setup'
], (Ember, startApp, env) ->
  App = null
  subject = null

  module 'Quiz Report Adapter',
    setup: ->
      App = startApp()
      subject = App.__container__.lookup('adapter:quizReport')

     teardown: ->
       Ember.run App, 'destroy'

  test 'it uses the report URL', ->
    Ember.run ->
      store = App.__container__.lookup('store:main')
      store.push('quizReport', {
        id: '14',
        url: '/api/v1/courses/1/quizzes/1/reports/14'
      })

    url = subject.buildURL 'quizReport', 14
    ok url.match('/api/v1/courses/1/quizzes/1/reports/14')
