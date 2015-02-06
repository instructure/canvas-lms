define [
  'compiled/quizzes/log_auditing/event_trackers/session_started'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  module 'Quizzes::LogAuditing::EventTrackers::SessionStarted'

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_SESSION_STARTED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  test 'capturing: it works', ->
    tracker = new Subject()
    capture = sinon.stub()
    tracker.install(capture)

    ok capture.called, 'it records a single event on loading'