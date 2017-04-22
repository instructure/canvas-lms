import $ from 'jquery'
import QuizArrowApplicator from 'quiz_arrows'
import 'quizzes'
import 'supercalc'
import 'quiz_rubric'
import 'compiled/quizzes/access_code'

$('#show_question_details').on('click', function () {
    // Create the quiz arrows
  if ($(this).is(':checked')) {
    const arrowApplicator = new QuizArrowApplicator()
    arrowApplicator.applyArrows()
  } else {
      // Delete all quiz arrows
    $('.answer_arrow').remove()
  }
})

  // Subscribe to custom event that is triggered as an 'aftersave' on a question form
$('body').on('saved', '.question', () => {
    // Remove all arrows and recreate all if option is checked
  $('.answer_arrow').remove()
  if ($('#show_question_details').is(':checked')) {
    const arrowApplicator = new QuizArrowApplicator()
    arrowApplicator.applyArrows()
  }
})
