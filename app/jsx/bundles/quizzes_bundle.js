require [
  'jquery'
  'quiz_arrows'
  'quizzes'
  'supercalc'
  'quiz_rubric'
  'compiled/quizzes/access_code'
], ($, QuizArrowApplicator) ->

  $('#show_question_details').on 'click', (e)->
    # Create the quiz arrows
    if $(this).is(':checked')
      arrowApplicator = new QuizArrowApplicator()
      arrowApplicator.applyArrows()
    else
      # Delete all quiz arrows
      $('.answer_arrow').remove()

  # Subscribe to custom event that is triggered as an 'aftersave' on a question form
  $('body').on 'saved', '.question', ->
    # Remove all arrows and recreate all if option is checked
    $('.answer_arrow').remove()
    if $('#show_question_details').is(':checked')
      arrowApplicator = new QuizArrowApplicator()
      arrowApplicator.applyArrows()
