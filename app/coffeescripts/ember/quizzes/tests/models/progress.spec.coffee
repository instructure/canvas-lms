define [
  'ic-ajax'
  'ember'
  'underscore'
  '../start_app'
  '../environment_setup'
], (ajax, Ember, _, startApp) ->

  {run} = Ember
  App = null
  subject = null
  timeout = null

  progressFixture = (attrs) ->
    _.extend {
      "completion": 0,
      "context_id": 1,
      "context_type": "Quizzes::QuizStatistics",
      "created_at": "2014-04-02T09:40:32Z",
      "id": 1,
      "message": null,
      "tag": "Quizzes::QuizStatistics",
      "updated_at": "2014-04-02T09:40:36Z",
      "user_id": null,
      "workflow_state": "running",
      "url": "http://localhost:3000/api/v1/progress/1"
    }, attrs

  module "Progress",
    setup: ->
      App = startApp()
      run ->
        container = App.__container__
        store = container.lookup 'store:main'
        subject = store.createRecord 'progress', progressFixture()
        # need to modify the adapter to use ic-ajax, which for some reason it's
        # not in the spec...
        adapter = container.lookup 'adapter:progress'
        adapter.ajax = (url, method) ->
          ajax.request({ url: url, type: method })
    teardown: ->
      clearTimeout timeout
      run App, 'destroy'

  testWithTimeout = (desc, callback) ->
    asyncTest desc, ->
      timeout = setTimeout (->
        ok false, "timed out"
        start()
      ), 1000

      callback()

  testWithTimeout '#trackCompletion: it polls until complete', ->
    expect 1

    ajax.defineFixture '/api/v1/progress/1',
      response: progressFixture(workflow_state: 'completed'),
      jqXHR: {}
      textStatus: 'success'

    run ->
      subject.trackCompletion(5).then ->
        ok true, "notifies me when it's done"
        start()

  testWithTimeout '#trackCompletion: it reports failures', ->
    expect 1

    ajax.defineFixture '/api/v1/progress/1',
      response: progressFixture(workflow_state: 'failed'),
      jqXHR: {}
      textStatus: 'success'

    run ->
      subject.trackCompletion(5).then(->
        ok false, "progress success callback should never be called"
        start()
      , ->
        ok true, "progress failure callback should be called"
        start()
      )
