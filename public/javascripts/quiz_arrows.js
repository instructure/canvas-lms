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
    var rightAnswers     = $('#questions.show_correct_answers:not(.survey_quiz) .selected_answer.correct_answer'),
        wrongAnswers     = $('#questions.show_correct_answers:not(.survey_quiz) .selected_answer.wrong_answer'),
        correctAnswers   = $('#questions.show_correct_answers:not(.survey_quiz) .question:not(.short_answer_question, #questions.show_correct_answers:not(.survey_quiz) .numerical_question) .correct_answer:not(.selected_answer)'),
        shortAnswers     = $('#questions.show_correct_answers:not(.survey_quiz):not(.survey_results) .short_answer_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .numerical_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .equation_combinations_holder_holder.calculated_question_answers'),
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
        creditNoneTpl    = $('<span />', { 'class': 'answer_arrow incorrect' });
        surveyAnswerTpl  = $('<span />', { 'class': 'answer_arrow info' });

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

    rightAnswers.append(rightTpl);
    wrongAnswers.append(wrongTpl);
    correctAnswers.append(correctTpl);
    shortAnswers.append(shortTpl);
    unansweredQ.append(unansweredTpl);
    creditPartial.append(creditPartialTpl);
    creditFull.append(creditFullTpl);
    creditNone.append(creditNoneTpl);
    surveyAnswers.append(surveyAnswerTpl);

    // adjust these down a little so they align better w/ answers.
    $('.short_answer_question .answer_arrow').css('top', 5);
  };
});
