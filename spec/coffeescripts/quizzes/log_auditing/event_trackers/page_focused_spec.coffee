define [
  'compiled/quizzes/log_auditing/event_trackers/page_focused'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  module 'Quizzes::LogAuditing::EventTrackers::PageFocused'

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_PAGE_FOCUSED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  test 'capturing: it works', ->
    tracker = new Subject()
    capture = @stub()
    tracker.install(capture)

    $(window).focus()
    ok capture.called, 'it captures page focus'

  test 'capturing: it throttles captures', ->
    capture = @spy()

    tracker = new Subject()
    tracker.install(capture)

    $(window).focus()
    $(window).blur()
    $(window).focus()
    $(window).blur()
    $(window).focus()

    equal capture.callCount, 1, 'it ignores rapidly repetitive focuses'
