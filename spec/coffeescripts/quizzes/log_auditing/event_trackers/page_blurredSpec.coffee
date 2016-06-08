define [
  'compiled/quizzes/log_auditing/event_trackers/page_blurred'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  module 'Quizzes::LogAuditing::EventTrackers::PageBlurred'

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_PAGE_BLURRED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  test 'capturing: it works', ->
    tracker = new Subject()
    capture = @stub()
    tracker.install(capture)

    $(window).blur()
    ok capture.called, 'it captures page blur'

  test 'capturing: it doesnt send events if in iframe (for RCE focusing)', ->
    tracker = new Subject()
    capture = @stub()
    tracker.install(capture)

    iframe = $('<iframe>').appendTo('body').focus()
    $(window).blur()
    ok capture.notCalled, 'it does not mark iframe focus as page blur'
    iframe.remove()

  test 'capturing: it throttles captures', ->
    capture = @spy()

    tracker = new Subject()
    tracker.install(capture)

    $(window).blur()
    $(window).focus()
    $(window).blur()
    $(window).focus()
    $(window).blur()

    equal capture.callCount, 1, 'it ignores rapidly repetitive blurs'
