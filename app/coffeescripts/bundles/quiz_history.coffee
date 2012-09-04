require [
  'jquery'
  'quiz_arrows'
  'quiz_inputs'
  'quiz_history'
], ($, createQuizArrows, disableInputs) ->
  $ ->
    createQuizArrows()
    disableInputs('[type=radio], [type=checkbox]')
