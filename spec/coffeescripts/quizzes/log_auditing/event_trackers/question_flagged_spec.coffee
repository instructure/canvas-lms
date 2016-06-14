define [
  'compiled/quizzes/log_auditing/event_trackers/question_flagged'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  module 'Quizzes::LogAuditing::EventTrackers::QuestionFlagged',
    setup: ->
    teardown: ->
      document.getElementById("fixtures").innerHTML = ""

  DEFAULTS = Subject.prototype.options

  createQuestion = (id) ->
    $question = $('<div />', { class: 'question', id: "question_#{id}" })
      .appendTo(document.getElementById("fixtures"))

    $('<a />', { class: 'flag_question' }).appendTo($question).on 'click', ->
      $question.toggleClass('marked')

    QUnit.done -> $question.remove()

    $question

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_QUESTION_FLAGGED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  test 'capturing: it works', ->
    capture = @stub()
    tracker = new Subject({
      questionSelector: '.question',
      questionMarkedClass: 'marked',
      buttonSelector: '.flag_question',
    })

    tracker.install(capture)

    $fakeQuestion = createQuestion('123')
    $fakeQuestion.find('a.flag_question').click()

    ok capture.calledWith({ questionId: '123', flagged: true })

    $fakeQuestion.find('a.flag_question').click()
    ok capture.calledWith({ questionId: '123', flagged: false })
