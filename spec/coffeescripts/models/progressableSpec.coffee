define ['compiled/models/progressable', 'Backbone'], (progressable, {Model}) ->

  progressUrl = '/progress'
  server = null
  clock = null
  model = null

  class QuizCSV extends Model
    @mixin progressable

  module 'progressable',
    setup: ->
      clock = sinon.useFakeTimers()
      model = new QuizCSV
      model.url = '/quiz_csv'
      server = sinon.fakeServer.create()
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
    teardown: ->
      server.restore()
      clock.restore()

  test 'set progress_url', ->
    spy = @spy()
    model.progressModel.on 'complete', spy
    model.on 'progressResolved', spy
    model.set progress_url: progressUrl
    server.respond()
    server.respond()
    ok spy.calledTwice, 'complete and progressResolved handlers called'
    equal model.progressModel.get('workflow_state'), 'completed'
    equal model.get('csv'), 'one,two,three'

  test 'set progress.url', ->
    spy = @spy()
    model.progressModel.on 'complete', spy
    model.on 'progressResolved', spy
    model.progressModel.set url: progressUrl, workflow_state: 'queued'
    server.respond()
    ok spy.calledTwice, 'complete and progressResolved handlers called'
    server.respond()
    server.respond()
    equal model.progressModel.get('workflow_state'), 'completed'
    equal model.get('csv'), 'one,two,three'
