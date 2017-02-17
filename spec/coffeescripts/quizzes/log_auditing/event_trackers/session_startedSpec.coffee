define [
  'compiled/quizzes/log_auditing/event_trackers/session_started'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  QUnit.module 'Quizzes::LogAuditing::EventTrackers::SessionStarted'

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_SESSION_STARTED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  QUnit.skip 'capturing: it works', ->
    tracker = new Subject()
    capture = @stub()

    tracker.install(capture)

    # this will never be ok because .install only triggers the
    # event if location.href.indexOf("question") == -1 && location.href.indexOf("take") > 0
    ok capture.called, 'it records a single event on loading'
