define [
  'compiled/quizzes/log_auditing/event'
  'compiled/quizzes/log_auditing/event_buffer'
  'compiled/quizzes/log_auditing/constants'
], (QuizEvent, EventBuffer, K) ->
  useLocalStorage = ->
    EventBuffer.setStorageAdapter(K.EVT_STORAGE_LOCAL_STORAGE)
  useMemoryStorage = ->
    EventBuffer.setStorageAdapter(K.EVT_STORAGE_MEMORY)

  module 'Quizzes::LogAuditing::EventBuffer',
    setup: ->
      useMemoryStorage()

    teardown: ->
      localStorage.removeItem(K.EVT_STORAGE_KEY)
      useMemoryStorage()

  test '#constructor: it auto-loads from localStorage', ->
    useLocalStorage()
    localStorage.setItem(K.EVT_STORAGE_KEY, JSON.stringify([{ event_type: 'some_event' }]))

    buffer = new EventBuffer()
    ok !buffer.isEmpty()

  test '#constructor: it does not auto-load from localStorage', ->
    useMemoryStorage()
    localStorage.setItem(K.EVT_STORAGE_KEY, JSON.stringify([{ event_type: 'some_event' }]))

    buffer = new EventBuffer()
    ok buffer.isEmpty()

  test '#push: it adds to the buffer', ->
    buffer = new EventBuffer()
    buffer.push(new QuizEvent('some_type'))

    ok !buffer.isEmpty()

  test '#push: it adds to the buffer and updates cache', ->
    useLocalStorage()

    buffer = new EventBuffer()
    buffer.push(new QuizEvent('some_type'))

    equal buffer.getLength(), 1

    another_buffer = new EventBuffer()
    equal another_buffer.getLength(), 1

  test '#toJSON', ->
    buffer = new EventBuffer()
    buffer.push(new QuizEvent('some_type', { foo: 'bar' }))
    json = buffer.toJSON()
    ok json instanceof Array
    equal json.length, 1
