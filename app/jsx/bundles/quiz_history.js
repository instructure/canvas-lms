require [
  'jquery'
  'quiz_arrows'
  'quiz_inputs'
  'quiz_history'
], ($, QuizArrowApplicator, inputMethods) ->
  $ ->
    arrowApplicator = new QuizArrowApplicator()
    arrowApplicator.applyArrows()
    inputMethods.disableInputs('[type=radio], [type=checkbox]')
    inputMethods.setWidths()
