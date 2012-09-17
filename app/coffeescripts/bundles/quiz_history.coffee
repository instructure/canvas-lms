require [
  'jquery'
  'quiz_arrows'
  'quiz_inputs'
  'quiz_history'
], ($, createQuizArrows, inputMethods) ->
  $ ->
    createQuizArrows()
    inputMethods.disableInputs('[type=radio], [type=checkbox]')
    inputMethods.setWidths()
