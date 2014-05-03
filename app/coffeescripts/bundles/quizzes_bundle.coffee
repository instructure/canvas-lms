require [
  'jquery'
  'quiz_arrows'
  'quizzes'
  'supercalc'
  'quiz_rubric'
], ($, CreateQuizArrows) ->

  $('#show_question_details').on 'click', (e)->
    # Create the quiz arrows
    if $(this).is(':checked')
      CreateQuizArrows()
    else
      # Delete all quiz arrows
      $('.answer_arrow').remove()

  # Subscribe to custom event that is triggered as an 'aftersave' on a question form
  $('body').on 'saved', '.question', ->
    # Remove all arrows and recreate all if option is checked
    $('.answer_arrow').remove()
    if $('#show_question_details').is(':checked')
        CreateQuizArrows()
