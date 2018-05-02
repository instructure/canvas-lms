/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// xsslint jqueryObject.property /Tpl$/

import I18n from 'i18n!quizzes.show'
import $ from 'jquery'
import {direction} from 'jsx/shared/helpers/rtlHelper'

// Create and append right/wrong arrows to all appropriate
// answers on a quiz results page.
export default class QuizArrowApplicator {
  constructor () {
    this.$questions = $('#questions.show_correct_answers:not(.survey_quiz)')
    this.rightAnswers = this.$questions.find('.selected_answer.correct_answer')
    this.wrongAnswers = this.$questions.find('.selected_answer.wrong_answer')
    this.correctAnswers = this.$questions.find('.question:not(.short_answer_question, .numerical_question, .matching_question) .correct_answer:not(.selected_answer)')
    this.editableMatches = $('#quiz_edit_wrapper').find(this.$questions.selector).find('.question.matching_question .correct_answer:not(.selected_answer)')
    this.readOnlyMatches = $('#quiz_show').find(this.$questions.selector).find('.question.matching_question .correct_answer:not(.selected_answer)')
    this.shortAnswers = this.$questions.filter(':not(.survey_results)').find('.short_answer_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .numerical_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .equation_combinations_holder_holder.calculated_question_answers')
    this.unansweredQ = $('.question.unanswered .header .question_name')
    this.creditPartial = $('#questions.suppress_correct_answers:not(.survey_results) .question.partial_credit .header .question_name')
    this.creditFull = $('#questions.suppress_correct_answers:not(.survey_results) .question.correct .header .question_name')
    this.creditNone = $('#questions.suppress_correct_answers:not(.survey_results) .question.incorrect:not(.unanswered) .header .question_name')
    this.surveyAnswers = $('#questions.survey_results .selected_answer')
    this.rightTpl = $('<span />', { class: 'answer_arrow correct' })
    this.wrongTpl = $('<span />', { class: 'answer_arrow incorrect' })
    this.correctTpl = $('<span />', { class: 'answer_arrow info' })
    this.shortTpl = $('<span />', { class: 'answer_arrow info' })
    this.unansweredTpl = $('<span />', { class: 'answer_arrow incorrect' })
    this.creditFullTpl = $('<span />', { class: 'answer_arrow correct' })
    this.creditPartialTpl = $('<span />', { class: 'answer_arrow incorrect' })
    this.creditNoneTpl = $('<span />', { class: 'answer_arrow incorrect' })
    this.surveyAnswerTpl = $('<span />', { class: 'answer_arrow info' })
  }

  applyCSS () {
    $.each([this.rightTpl, this.wrongTpl, this.correctTpl, this.shortTpl, this.surveyAnswerTpl], function () {
      this.css({ [direction('left')]: -128, top: 5 })
    })
    $.each([this.unansweredTpl, this.creditFullTpl, this.creditNoneTpl, this.creditPartialTpl], function () {
      this.css({ [direction('left')]: -108, top: 9 })
    })
  }

  applyCorrectAndIncorrectArrows () {
    this.rightTpl.text(I18n.t('answers.correct', 'Correct!'))
    this.wrongTpl.text(I18n.t('answers.you_answered', 'You Answered'))
    this.correctTpl.text(I18n.t('answers.right', 'Correct Answer'))
    this.shortTpl.text(I18n.t('answers.correct_answers', 'Correct Answers'))
    this.creditFullTpl.text(I18n.t('answers.correct', 'Correct!'))
    this.creditPartialTpl.text(I18n.t('answers.partial', 'Partial'))
    this.creditNoneTpl.text(I18n.t('answers.incorrect', 'Incorrect'))

    this.rightAnswers.prepend(this.rightTpl)
    this.wrongAnswers.prepend(this.wrongTpl)
    this.correctAnswers.prepend(this.correctTpl)
    this.editableMatches.parent().before(this.correctTpl)
    this.readOnlyMatches.prepend(this.correctTpl)
    this.shortAnswers.prepend(this.shortTpl)
    this.creditPartial.prepend(this.creditPartialTpl)
    this.creditFull.prepend(this.creditFullTpl)
    this.creditNone.prepend(this.creditNoneTpl)
  }

  applyAnsweredAndUnansweredArrows () {
    this.unansweredTpl.text(I18n.t('answers.unanswered', 'Unanswered'))
    this.surveyAnswerTpl.text(I18n.t('answers.you_answered', 'You Answered'))
    this.unansweredQ.prepend(this.unansweredTpl)
    this.surveyAnswers.prepend(this.surveyAnswerTpl)
  }

  makeArrowsAccessible () {
    // adjust these down a little so they align better w/ answers.
    $('.short_answer_question .answer_arrow').css('top', 5)

    // CNVS-6634:
    //
    // Enable a11y for <input /> elements that receive focus by speaking the
    // answer result which is contained in the arrow marker.
    $('#questions .answer_arrow').each(function () {
      const $arrow = $(this)

      // This might be either an ".answer", or an ".answers_wrapper" in case
      // of multiple-answer questions, we'll be using it to find the target(s),
      // and to generate an ID, see below.
      const $answer = $arrow.parent()

      // The element(s) that will be tagged with @aria-describedby
      let $target = $()

      // @aria-describedby needs to reference an @id, so we must stamp each
      // arrow with a proper id: (conflicts are resolved later)
      let arrowId = $answer.prop('id')

      // User-generated incorrect answers are not tagged with an @id, so we
      // auto-generate ones:
      if (!arrowId) {
        arrowId = ['user_answer', ++this.idGenerator].join('_')
      }

      // Suffix it with _arrow to avoid conflicts
      arrowId = [arrowId, 'arrow'].join('_')

      // Stamp the arrow
      $arrow.prop('id', arrowId)

      // Locate the targets.
      //
      // The :visible filter is required because .answer nodes will contain
      // <input /> items for each question type's answers, but only the actual
      // question type answers will be visible, and we need those.
      $target = $answer.find('input:visible')

      // For the question types below, there won't be any visible <input />,
      // so we'll be tagging the ".answers_wrapper" ($answer) node instead:
      //
      // - Fill in the blanks questions
      // - Numerical questions
      //
      // (This may only occur if the student chooses a wrong answer.)
      if (!$target.length) {
        $target = $answer
      }

      // We're done, define the @aria-describedby node referencing the @id we
      // got above.
      $target.attr('aria-describedby', arrowId)
    })
  }

  applyArrows () {
    this.applyCSS()
    if (!ENV.IS_SURVEY) this.applyCorrectAndIncorrectArrows()
    this.applyAnsweredAndUnansweredArrows()
    this.makeArrowsAccessible()
  }
}
