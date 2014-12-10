define [
  'compiled/quizzes/log_auditing/event'
], (QuizEvent) ->
  module 'Quizzes::LogAuditing::QuizEvent',
    setup: ->
    teardown: ->

  test '#constructor', ->
    ok !!(new QuizEvent('some_event_type')),
      'it can be created'

    throws (-> new QuizEvent()), /An event type must be specified./,
      'it requires an event type'

  test '#constructor: auto-generates an ID for internal tracking', ->
    evt = new QuizEvent('some_event_type')
    ok (evt._id && evt._id.length > 0)

  test 'QuizEvent.fromJSON', ->
    descriptor = {
      created_at: (new Date()).toJSON(),
      event_type: 'some_type',
      event_data: {
        foo: 'bar'
      }
    }

    event = QuizEvent.fromJSON(descriptor)

    equal event.type, descriptor.event_type,
      'it parses the type'

    propEqual event.data, descriptor.event_data,
      'it parses the custom data'

    deepEqual event.recordedAt, new Date(descriptor.created_at),
      'it parses the recording timestamp'