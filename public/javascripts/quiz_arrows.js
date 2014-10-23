/**
 * Copyright (C) 2012 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define(['i18n!quizzes.show', 'jquery'], function(I18n, $) {
  // Create and append right/wrong arrows to all appropriate
  // answers on a quiz results page.
  return function() {
    var $questions = $('#questions.show_correct_answers:not(.survey_quiz)');
    var rightAnswers     = $questions.find('.selected_answer.correct_answer'),
        wrongAnswers     = $questions.find('.selected_answer.wrong_answer'),
        correctAnswers   = $questions.find('.question:not(.short_answer_question, .numerical_question, .matching_question) .correct_answer:not(.selected_answer)'),
        editableMatches  = $('#quiz_edit_wrapper').find($questions.selector).find('.question.matching_question .correct_answer:not(.selected_answer)'),
        readOnlyMatches  = $('#quiz_show').find($questions.selector).find('.question.matching_question .correct_answer:not(.selected_answer)'),
        shortAnswers     = $questions.filter(':not(.survey_results)').find('.short_answer_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .numerical_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .equation_combinations_holder_holder.calculated_question_answers'),
        unansweredQ      = $('.question.unanswered .header .question_name'),
        creditPartial    = $('#questions.suppress_correct_answers:not(.survey_results) .question.partial_credit .header .question_name'),
        creditFull       = $('#questions.suppress_correct_answers:not(.survey_results) .question.correct .header .question_name'),
        creditNone       = $('#questions.suppress_correct_answers:not(.survey_results) .question.incorrect:not(.unanswered) .header .question_name'),
        surveyAnswers    = $('#questions.survey_results .selected_answer'),
        rightTpl         = $('<span />', { 'class': 'answer_arrow correct' }),
        wrongTpl         = $('<span />', { 'class': 'answer_arrow incorrect' }),
        correctTpl       = $('<span />', { 'class': 'answer_arrow info' }),
        shortTpl         = $('<span />', { 'class': 'answer_arrow info' }),
        unansweredTpl    = $('<span />', { 'class': 'answer_arrow incorrect' }),
        creditFullTpl    = $('<span />', { 'class': 'answer_arrow correct' }),
        creditPartialTpl = $('<span />', { 'class': 'answer_arrow incorrect' }),
        creditNoneTpl    = $('<span />', { 'class': 'answer_arrow incorrect' }),
        surveyAnswerTpl  = $('<span />', { 'class': 'answer_arrow info' }),
        idGenerator      = 0;

    $.each([rightTpl, wrongTpl, correctTpl, shortTpl, surveyAnswerTpl], function() {
      this.css({ left: -128, top: 5 });
    });
    $.each([unansweredTpl, creditFullTpl, creditNoneTpl, creditPartialTpl], function() {
      this.css({ left: -108, top: 9 });
    });


    rightTpl.text(I18n.t('answers.correct', 'Correct!'));
    wrongTpl.text(I18n.t('answers.you_answered', 'You Answered'));
    correctTpl.text(I18n.t('answers.right', 'Correct Answer'));
    shortTpl.text(I18n.t('answers.correct_answers', 'Correct Answers'));
    unansweredTpl.text(I18n.t('answers.unanswered', 'Unanswered'));
    creditFullTpl.text(I18n.t('answers.correct', 'Correct!'));
    creditPartialTpl.text(I18n.t('answers.partial', 'Partial'));
    creditNoneTpl.text(I18n.t('answers.incorrect', 'Incorrect'));
    surveyAnswerTpl.text(I18n.t('answers.you_answered', 'You Answered'));

    rightAnswers.prepend(rightTpl);
    wrongAnswers.prepend(wrongTpl);
    correctAnswers.prepend(correctTpl);
    editableMatches.parent().before(correctTpl);
    readOnlyMatches.prepend(correctTpl);
    shortAnswers.prepend(shortTpl);
    unansweredQ.prepend(unansweredTpl);
    creditPartial.prepend(creditPartialTpl);
    creditFull.prepend(creditFullTpl);
    creditNone.prepend(creditNoneTpl);
    surveyAnswers.prepend(surveyAnswerTpl);

    // adjust these down a little so they align better w/ answers.
    $('.short_answer_question .answer_arrow').css('top', 5);

    // CNVS-6634:
    //
    // Enable a11y for <input /> elements that receive focus by speaking the
    // answer result which is contained in the arrow marker.
    $('#questions .answer_arrow').each(function() {
      var $arrow  = $(this),

          // This might be either an ".answer", or an ".answers_wrapper" in case
          // of multiple-answer questions, we'll be using it to find the target(s),
          // and to generate an ID, see below.
          $answer = $arrow.parent(),

          // The element(s) that will be tagged with @aria-describedby
          $target = $(),

          // @aria-describedby needs to reference an @id, so we must stamp each
          // arrow with a proper id: (conflicts are resolved later)
          arrowId = $answer.prop('id');

      // User-generated incorrect answers are not tagged with an @id, so we
      // auto-generate ones:
      if (!arrowId) {
        arrowId = [ 'user_answer', ++idGenerator ].join('_');
      }

      // Suffix it with _arrow to avoid conflicts
      arrowId = [ arrowId, 'arrow' ].join('_');

      // Stamp the arrow
      $arrow.prop('id', arrowId);

      // Locate the targets.
      //
      // The :visible filter is required because .answer nodes will contain
      // <input /> items for each question type's answers, but only the actual
      // question type answers will be visible, and we need those.
      $target = $answer.find('input:visible');

      // For the question types below, there won't be any visible <input />,
      // so we'll be tagging the ".answers_wrapper" ($answer) node instead:
      //
      // - Fill in the blanks questions
      // - Numerical questions
      //
      // (This may only occur if the student chooses a wrong answer.)
      if (!$target.length) {
        $target = $answer;
      }

      // We're done, define the @aria-describedby node referencing the @id we
      // got above.
      $target.attr('aria-describedby', arrowId);
    });
  };
});
