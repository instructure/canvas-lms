require [
  'quiz_arrows'
  'quizzes'
  'supercalc'
  'quiz_rubric'
], (CreateQuizArrows) ->
  $('#show_question_details').on 'click', (e)->
    # Create the quiz arrows
    if $(this).is(':checked')
      CreateQuizArrows()
    else
      # Delete any quiz arrows
      $('.answer_arrow').remove()

  $('.edit_question_link').on 'click', (e)->
    $(this).find('.answer_arrow').remove()
  $('.cancel_link').on 'click', (e)->
    if $('#show_question_details').is(':checked')
      CreateQuizArrows($(this).closest('.question'))
  # Subscribe to custom event that is triggered as an 'aftersave' on a question form
  $('body').on 'saved', '.question', ->
    if $('#show_question_details').is(':checked')
      CreateQuizArrows($(this).closest('.question_holder'))
