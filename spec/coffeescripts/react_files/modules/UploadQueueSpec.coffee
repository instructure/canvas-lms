define [
  'compiled/react_files/modules/UploadQueue'
  'jquery'
], (UploadQueue, $) ->

  mockFileUploader = (file) ->
    {
      upload: ->
        promise = $.Deferred()
        window.setTimeout ->
          promise.resolve()
        , 2
        promise
      file: file
    }

  mockAttemptNext = ->
    #noop

  module 'UploadQueue',
    setup: ->
      @queue = UploadQueue

    teardown: ->
      delete @queue


  test 'Enqueues uploads, flush clears', ->
    original = @queue.attemptNextUpload
    @queue.attemptNextUpload = mockAttemptNext

    @queue.enqueue {foo: 'bar'}
    equal(@queue.length(), 1)
    @queue.enqueue {baz: 'zoo'}
    equal(@queue.length(), 2)
    @queue.flush()
    equal(@queue.length(), 0)

    @queue.attemptNextUpload = original


  test 'processes one upload at a time', ->
    expect(2)
    original = @queue.createUploader
    @queue.createUploader = mockFileUploader

    @queue.enqueue 'foo'
    @queue.enqueue 'bar'
    @queue.enqueue 'baz'
    equal(@queue.length(), 2) # first item starts, remainder are waitingj
    stop()
    window.setTimeout =>
      start()
      equal(@queue.length(), 1) #after two more ticks there is only one remaining
    , 2

    @queue.createUploader = original

  test 'dequeue removes top of the queue', ->
    original = @queue.attemptNextUpload
    @queue.attemptNextUpload = mockAttemptNext

    foo = {name:'foo'}
    @queue.enqueue foo
    equal(@queue.length(), 1)
    @queue.enqueue {baz: 'zoo'}
    equal(@queue.length(), 2)
    equal(@queue.dequeue().file, foo)

    @queue.attemptNextUpload = original

