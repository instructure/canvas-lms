define [
  'compiled/quizzes/log_auditing/constants'
  'compiled/quizzes/log_auditing/event'
  'compiled/quizzes/log_auditing/event_manager'
  'compiled/quizzes/log_auditing/event_tracker'
  'vendor/backbone'
], (K, QuizEvent, EventManager, EventTracker, Backbone) ->
  evtManager = null
  module 'Quizzes::LogAuditing::EventManager',
    teardown: ->
      evtManager.stop() if evtManager && evtManager.isRunning()

  testEventFactory = new Backbone.Model()

  class TestEventTracker extends EventTracker
    eventType: 'test_event'

    install: (deliver) ->
      testEventFactory.on 'change', deliver


  test '#start and #stop: should work', ->
    evtManager = new EventManager()
    evtManager.start()
    ok evtManager.isRunning()

    evtManager.stop()
    ok !evtManager.isRunning()

  module 'Quizzes::LogAuditing::EventManager - Event delivery',
    setup: ->
      this.server = sinon.fakeServer.create()

    teardown: ->
      this.server.restore()
      evtManager.stop() if evtManager && evtManager.isRunning()

  test 'it should deliver events', ->
    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events'
    })

    evtManager.registerTracker(TestEventTracker)
    evtManager.start()

    testEventFactory.trigger('change')

    ok evtManager.isDirty(),
      'it correctly reports whether it has any events pending delivery'

    evtManager.deliver()

    equal this.server.requests.length, 1
    equal this.server.requests[0].url, '/events',
      'it respects the delivery URL'

    payload = JSON.parse(this.server.requests[0].requestBody)

    ok payload.hasOwnProperty('quiz_submission_events'),
      'it scopes event payload with "quiz_submission_events"'

    equal payload.quiz_submission_events[0].event_type, 'test_event',
      'it includes the serialized events'

    ok evtManager.isDelivering(),
      'it correctly reports whether a delivery is in progress'

    this.server.requests[0].respond(204)

    ok !evtManager.isDelivering(),
      "it untracks the delivery once it's synced with the server"

    ok !evtManager.isDirty(),
      "it flushes its buffer when sync is complete"
