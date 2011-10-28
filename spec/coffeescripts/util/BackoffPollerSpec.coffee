define ['compiled/util/BackoffPoller'], (BackoffPoller)->

  module 'BackoffPoller',
    setup: ->
      @ran_callback = false
      @callback = =>
        @ran_callback = true

  asyncTest 'should keep polling when it gets a "continue"', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'continue'
    , backoffFactor: 1, baseInterval: 10, maxAttempts: 100

    poller.start().then(@callback)

    setTimeout =>
      ok poller.running, "poller should be running"
      poller.stop(false)
      start()
    , 100

  asyncTest 'should reset polling when it gets a "reset"', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'reset'
    , backoffFactor: 1, baseInterval: 10, maxAttempts: 100
    poller.start().then(@callback)

    setTimeout =>
      ok poller.running, "poller should be running"
      ok poller.attempts <= 1, "counter should be reset" # either zero or one, depending on whether we're waiting for a timeout or an ajax call
      poller.stop(false)
      start()
    , 100

  asyncTest 'should stop polling when it gets a "stop"', ->
    count = 0
    poller = new BackoffPoller 'fixtures/ok.json', ->
      if count++ > 3 then 'stop' else 'continue'
    , backoffFactor: 1, baseInterval: 10

    poller.start().then(@callback)

    setTimeout =>
      ok not poller.running, "poller should be stopped"
      ok @ran_callback, "poller should have run callbacks"
      start()
    , 100

  asyncTest 'should abort polling when it hits maxAttempts', ->
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'continue'
    , backoffFactor: 1, baseInterval: 10, maxAttempts: 3

    poller.start().then(@callback)

    setTimeout =>
      ok not poller.running, "poller should be stopped"
      ok not @ran_callback, "poller should not have run callbacks"
      start()
    , 100

  asyncTest 'should abort polling when it gets anything else', ->
    count = 0
    poller = new BackoffPoller 'fixtures/ok.json', ->
      'omgwtfbbq'
    , baseInterval: 10

    poller.start().then(@callback)

    setTimeout =>
      ok not poller.running, "poller should be stopped"
      ok not @ran_callback, "poller should not have run callbacks"
      start()
    , 100
