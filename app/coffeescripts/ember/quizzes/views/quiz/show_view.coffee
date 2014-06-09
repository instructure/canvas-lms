define [
  'ember'
  'i18n!quiz_submission'
], (Ember, I18n) ->

  Ember.View.extend
    # add response arrows after legacy submission html promise resolves
    addLegacySubmissionArrows: (->
      return unless @get('controller.quizSubmissionHtml.html')
      Ember.run.next(this, @buildLegacyArrows)
    ).observes('controller.quizSubmissionHtml.html')

    # build correct/incorrect arrows to the legacy quiz submission html
    buildLegacyArrows: ( ->
      return unless @get('controller.quizSubmissionHtml.html')

      rightAnswers = $("#questions.show_correct_answers:not(.survey_quiz) .selected_answer.correct_answer")
      wrongAnswers = $("#questions.show_correct_answers:not(.survey_quiz) .selected_answer.wrong_answer")
      correctAnswers = $("#questions.show_correct_answers:not(.survey_quiz) .question:not(.short_answer_question, #questions.show_correct_answers:not(.survey_quiz) .numerical_question) .correct_answer:not(.selected_answer)")
      shortAnswers = $("#questions.show_correct_answers:not(.survey_quiz):not(.survey_results) .short_answer_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .numerical_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .equation_combinations_holder_holder.calculated_question_answers")
      unansweredQ = $(".question.unanswered .header .question_name")
      creditPartial = $("#questions.suppress_correct_answers:not(.survey_results) .question.partial_credit .header .question_name")
      creditFull = $("#questions.suppress_correct_answers:not(.survey_results) .question.correct .header .question_name")
      creditNone = $("#questions.suppress_correct_answers:not(.survey_results) .question.incorrect:not(.unanswered) .header .question_name")
      surveyAnswers = $("#questions.survey_results .selected_answer")

      rightTpl = $("<span />", {class: "answer_arrow correct"})
      wrongTpl = $("<span />", {class: "answer_arrow incorrect"})
      correctTpl = $("<span />", {class: "answer_arrow info"})
      shortTpl = $("<span />", {class: "answer_arrow info"})
      unansweredTpl = $("<span />", {class: "answer_arrow incorrect"})
      creditFullTpl = $("<span />", {class: "answer_arrow correct"})
      creditPartialTpl = $("<span />", {class: "answer_arrow incorrect"})
      creditNoneTpl = $("<span />", {class: "answer_arrow incorrect"})
      surveyAnswerTpl = $("<span />", {class: "answer_arrow info"})

      idGenerator = 0
      $.each [rightTpl, wrongTpl, correctTpl, shortTpl, surveyAnswerTpl], ->
        @css({left: -128, top: 5})

      $.each [unansweredTpl, creditFullTpl, creditNoneTpl, creditPartialTpl], ->
        @css({left: -108, top: 9})

      rightTpl.text I18n.t("answers.correct", "Correct!")
      wrongTpl.text I18n.t("answers.you_answered", "You Answered")
      correctTpl.text I18n.t("answers.right", "Correct Answer")
      shortTpl.text I18n.t("answers.correct_answers", "Correct Answers")
      unansweredTpl.text I18n.t("answers.unanswered", "Unanswered")
      creditFullTpl.text I18n.t("answers.correct", "Correct!")
      creditPartialTpl.text I18n.t("answers.partial", "Partial")
      creditNoneTpl.text I18n.t("answers.incorrect", "Incorrect")
      surveyAnswerTpl.text I18n.t("answers.you_answered", "You Answered")

      rightAnswers.prepend rightTpl
      wrongAnswers.prepend wrongTpl
      correctAnswers.prepend correctTpl
      shortAnswers.prepend shortTpl
      unansweredQ.prepend unansweredTpl
      creditPartial.prepend creditPartialTpl
      creditFull.prepend creditFullTpl
      creditNone.prepend creditNoneTpl
      surveyAnswers.prepend surveyAnswerTpl

      $(".short_answer_question .answer_arrow").css "top", 5

      $("#questions .answer_arrow").each ->
        $arrow = $(this)
        $answer = $arrow.parent()
        $target = $()
        arrowId = $answer.prop("id")
        arrowId = ["user_answer", ++idGenerator].join("_") unless arrowId
        arrowId = [arrowId, "arrow"].join("_")

        $arrow.prop "id", arrowId
        $target = $answer.find("input:visible")
        $target = $answer  unless $target.length
        $target.attr "aria-describedby", arrowId
    )

