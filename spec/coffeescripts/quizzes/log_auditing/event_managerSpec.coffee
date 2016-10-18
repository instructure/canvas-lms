define [
  'compiled/quizzes/log_auditing/constants'
  'compiled/quizzes/log_auditing/event'
  'compiled/quizzes/log_auditing/event_manager'
  'compiled/quizzes/log_auditing/event_tracker'
  'node_modules-version-of-backbone'
], (K, QuizEvent, EventManager, EventTracker, Backbone) ->
  module 'Quizzes::LogAuditing::EventManager',
    teardown: ->
      this.evtManager.stop() if this.evtManager && this.evtManager.isRunning()

  test '#start and #stop: should work', ->
    this.evtManager = new EventManager()
    this.evtManager.start()
    ok this.evtManager.isRunning()

    this.evtManager.stop()
    ok !this.evtManager.isRunning()

  module 'Quizzes::LogAuditing::EventManager - Event delivery',
    setup: ->
      this.server = sinon.fakeServer.create()

      specThis = this
      class TestEventTracker extends EventTracker
        eventType: 'test_event'

        install: (deliver) ->
          specThis.testEventFactory.on 'change', deliver
      this.TestEventTracker = TestEventTracker
      this.testEventFactory = new Backbone.Model()

    teardown: ->
      this.server.restore()
      this.evtManager.stop() if this.evtManager && this.evtManager.isRunning()

  test 'it should deliver events', ->
    this.evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events'
    })

    this.evtManager.registerTracker(this.TestEventTracker)
    this.evtManager.start()

    this.testEventFactory.trigger('change')

    ok this.evtManager.isDirty(),
      'it correctly reports whether it has any events pending delivery'

    this.evtManager.deliver()

    equal this.server.requests.length, 1
    equal this.server.requests[0].url, '/events',
      'it respects the delivery URL'

    payload = JSON.parse(this.server.requests[0].requestBody)

    ok payload.hasOwnProperty('quiz_submission_events'),
      'it scopes event payload with "quiz_submission_events"'

    equal payload.quiz_submission_events[0].event_type, 'test_event',
      'it includes the serialized events'

    ok this.evtManager.isDelivering(),
      'it correctly reports whether a delivery is in progress'

    this.server.requests[0].respond(204)

    ok !this.evtManager.isDelivering(),
      "it untracks the delivery once it's synced with the server"

    ok !this.evtManager.isDirty(),
      "it flushes its buffer when sync is complete"

  test "it should drop trackers", ->
    this.evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events'
    })
    this.evtManager.start()
    this.evtManager.registerTracker(this.TestEventTracker)
    this.evtManager.unregisterAllTrackers()
    this.testEventFactory.trigger("change")

    ok !this.evtManager.isDirty(), "it doesn't have any active trackers"