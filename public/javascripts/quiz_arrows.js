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
    var rightAnswers   = $('.selected_answer.correct_answer'),
        wrongAnswers   = $('.selected_answer.wrong_answer'),
        correctAnswers = $('.question:not(.short_answer_question, .numerical_question) .correct_answer:not(.selected_answer)'),
        shortAnswers   = $('.short_answer_question .answers_wrapper, .numerical_question .answers_wrapper'),
        unansweredQ    = $('.question.unanswered .header .question_name'),
        rightTpl       = $('<span />', { 'class': 'answer_arrow correct' }),
        wrongTpl       = $('<span />', { 'class': 'answer_arrow incorrect' }),
        correctTpl     = $('<span />', { 'class': 'answer_arrow info' }),
        shortTpl       = $('<span />', { 'class': 'answer_arrow info' }),
        unansweredTpl  = $('<span />', { 'class': 'answer_arrow incorrect' }).css({ left: -108, top: 5 });

    $.each([rightTpl, wrongTpl, correctTpl, shortTpl], function() {
      this.css({ left: -128, top: 0 });
    });


    rightTpl.text(I18n.t('answers.correct', 'Correct!'));
    wrongTpl.text(I18n.t('answers.incorrect', 'You Answered'));
    correctTpl.text(I18n.t('answers.right', 'Correct Answer'));
    shortTpl.text(I18n.t('answers.correct_answers', 'Correct Answers'));
    unansweredTpl.text(I18n.t('answers.unanswered', 'Unanswered'));

    rightAnswers.append(rightTpl);
    wrongAnswers.append(wrongTpl);
    correctAnswers.append(correctTpl);
    shortAnswers.append(shortTpl);
    unansweredQ.append(unansweredTpl);

    // adjust these downw a little so they align better w/ answers.
    $('.short_answer_question .answer_arrow').css('top', 5);
  };
});
