define [
  'quiz_arrows'
  'helpers/fakeENV'
], (QuizArrowApplicator, fakeENV) ->

  QUnit.module 'QuizArrowApplicator',
    setup: ->
      fakeENV.setup()
      @arrowApplicator = new QuizArrowApplicator()

    teardown: ->
      fakeENV.teardown()

  test "applies 'correct' and 'incorrect' arrows when the quiz is not a survey", ->
    @spy(@arrowApplicator, 'applyCorrectAndIncorrectArrows')
    ENV.IS_SURVEY = false
    @arrowApplicator.applyArrows()
    ok @arrowApplicator.applyCorrectAndIncorrectArrows.calledOnce

  test "does not apply 'correct' and 'incorrect' arrows when the quiz is a survey", ->
    @spy(@arrowApplicator, 'applyCorrectAndIncorrectArrows')
    ENV.IS_SURVEY = true
    @arrowApplicator.applyArrows()
    ok @arrowApplicator.applyCorrectAndIncorrectArrows.notCalled
