define ['compiled/models/Progress'], (Progress) ->

  server = null
  clock = null
  model = null

  QUnit.module 'progressable',
    setup: ->
      server = sinon.fakeServer.create()
      clock = sinon.useFakeTimers()
      model = new Progress
      # sinon won't send different data to the same url, so we change it
      model.url = ->
        '/steve/' + new Date().getTime()
    teardown: ->
      server.restore()
      clock.restore()

  respond = (data) ->
    server.respond("GET", model.url(),
      [200, { "Content-Type": "application/json"}, JSON.stringify(data)]
    )

  test 'polls the progress api until the job is finished', ->
    spy = @spy()
    model.on 'complete', spy
    model.poll()
    respond workflow_state: 'queued'
    equal model.get('workflow_state'), 'queued'
    clock.tick 1000
    respond workflow_state: 'running'
    equal model.get('workflow_state'), 'running'
    clock.tick 1000
    respond workflow_state: 'completed'
    equal model.get('workflow_state'), 'completed'
    ok spy.calledOnce
