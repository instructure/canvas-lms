define ['compiled/models/progressable', 'Backbone'], (progressable, {Model}) ->

  server = null
  clock = null
  model = null

  class QuizCSV extends Model
    @mixin progressable

  module 'progressable',
    setup: ->
      server = sinon.fakeServer.create()
      clock = sinon.useFakeTimers()
      model = new QuizCSV
      model.url = '/quiz_csv'
    teardown: ->
      server.restore()
      clock.restore()

  test 'crap', ->
    progressUrl = '/progress'
    server.respondWith('GET', progressUrl, [
      200,
      { "Content-Type": "application/json"},
      '{"workflow_state": "completed"}'
    ])
    server.respondWith('GET', model.url, [
      200,
      { "Content-Type": "application/json"},
      '{"csv": "one,two,three"}'
    ])
    spy = sinon.spy()
    model.progressModel.on 'complete', spy
    model.on 'progressResolved', spy
    model.set progress_url: progressUrl
    server.respond()
    server.respond()
    ok spy.calledTwice, 'complete and progressResoled handlers called'
    equal model.progressModel.get('workflow_state'), 'completed'
    equal model.get('csv'), 'one,two,three'



