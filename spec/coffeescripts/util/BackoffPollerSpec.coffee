define ['compiled/util/BackoffPoller'], (BackoffPoller)->

  module 'BackoffPoller',
    setup: ->
      @ran_callback = false
      @callback = =>
        @ran_callback = true
      @clock = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
      @server.respondWith 'fixtures/ok.json', '{"status":"ok"}'

    teardown: ->
      @clock.restore()
      @server.restore()

  test 'should keep polling when it gets a "continue"', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'continue'
    , backoffFactor: 1, baseInterval: 10, maxAttempts: 100
    poller.start().then(@callback)

    # let the first interval expire, and then respond to the request
    @clock.tick 10
    @server.respond()

    ok poller.running, "poller should be running"
    poller.stop(false)

  test 'should reset polling when it gets a "reset"', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'reset'
    , backoffFactor: 1, baseInterval: 10, maxAttempts: 100
    poller.start().then(@callback)

    # let the first interval expire, and then respond to the request
    @clock.tick 10
    @server.respond()

    ok poller.running, "poller should be running"
    ok poller.attempts <= 1, "counter should be reset" # either zero or one, depending on whether we're waiting for a timeout or an ajax call
    poller.stop(false)

  test 'should stop polling when it gets a "stop"', ->
    count = 0
    poller = new BackoffPoller 'fixtures/ok.json', ->
      if count++ > 3 then 'stop' else 'continue'
    , backoffFactor: 1, baseInterval: 10
    poller.start().then(@callback)

    # let the four 'continue' intervals expire, responding after each
    for i in [0...4]
      @clock.tick 10
      @server.respond()

    ok poller.running, "poller should be running"

    # let the final 'stop' interval expire, and then respond to the request
    @clock.tick 10
    @server.respond()

    ok not poller.running, "poller should be stopped"
    ok @ran_callback, "poller should have run callbacks"

  test 'should abort polling when it hits maxAttempts', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'continue'
    , backoffFactor: 1, baseInterval: 10, maxAttempts: 3
    poller.start().then(@callback)

    # let the first two intervals expire, responding after each
    for i in [0...2]
      @clock.tick 10
      @server.respond()

    ok poller.running, "poller should be running"

    # let the final interval expire, and then respond to the request
    @clock.tick 10
    @server.respond()

    ok not poller.running, "poller should be stopped"
    ok not @ran_callback, "poller should not have run callbacks"

  test 'should abort polling when it gets anything else', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'omgwtfbbq'
    , baseInterval: 10
    poller.start().then(@callback)

    # let the interval expire, and then respond to the request
    @clock.tick 10
    @server.respond()

    ok not poller.running, "poller should be stopped"
    ok not @ran_callback, "poller should not have run callbacks"
