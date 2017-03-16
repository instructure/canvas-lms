import $ from 'jquery'
import QuizArrowApplicator from 'quiz_arrows'
import inputMethods from 'quiz_inputs'
import 'quiz_history'

$(() => {
  const arrowApplicator = new QuizArrowApplicator()
  arrowApplicator.applyArrows()
  inputMethods.disableInputs('[type=radio], [type=checkbox]')
  inputMethods.setWidths()
})
