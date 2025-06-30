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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {direction} from '@canvas/i18n/rtlHelper'

const I18n = createI18nScope('quizzes.show')

// Create and append right/wrong arrows to all appropriate
// answers on a quiz results page.
export default class QuizArrowApplicator {
  constructor() {
    this.idGenerator = 0
    this.$questions = $('#questions.show_correct_answers:not(.survey_quiz)')
    this.rightAnswers = this.$questions.find('.selected_answer.correct_answer')
    this.wrongAnswers = this.$questions.find('.selected_answer.wrong_answer')
    this.correctAnswers = this.$questions.find(
      '.question:not(.short_answer_question, .numerical_question, .matching_question) .correct_answer:not(.selected_answer)',
    )
    this.editableMatches = $('#quiz_edit_wrapper')
      .find(this.$questions.selector)
      .find('.question.matching_question .correct_answer:not(.selected_answer)')
    this.readOnlyMatches = $('#quiz_show')
      .find(this.$questions.selector)
      .find('.question.matching_question .correct_answer:not(.selected_answer)')
    this.shortAnswers = this.$questions
      .filter(':not(.survey_results)')
      .find(
        '.short_answer_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .numerical_question .answers_wrapper, #questions.show_correct_answers:not(.survey_results):not(.survey_quiz) .equation_combinations_holder_holder.calculated_question_answers',
      )

    this.shortAnswers = this.$questions
      .filter(':not(.survey_results)')
      .find(
        '#questions:not(.survey_results):not(.survey_quiz) .numerical_question .answers_wrapper',
      )

    this.unansweredQ = $('#questions:not(.question_editing) .question.unanswered')
    this.answeredCorrectQ = $('#questions:not(.survey_results) .question.correct')
    this.answeredIncorrectQ = $(
      '#questions:not(.survey_results) .question.incorrect:not(.unanswered)',
    )

    this.supressAnswers = $('#questions.suppress_correct_answers:not(.survey_results)').length > 0
    this.creditPartial = $(
      '#questions.suppress_correct_answers:not(.survey_results) .question.partial_credit',
    )
    this.creditFull = $(
      '#questions.suppress_correct_answers:not(.survey_results) .question.correct',
    )
    this.creditNone = $(
      '#questions.suppress_correct_answers:not(.survey_results) .question.incorrect:not(.unanswered)',
    )

    this.rightTpl = $('<span />', {class: 'answer_arrow correct'})
    this.wrongTpl = $('<span />', {class: 'answer_arrow incorrect'})
    this.correctTpl = $('<span />', {class: 'answer_arrow info'})

    this.shortTpl = $('<span />', {class: 'answer_arrow info'})

    this.creditFullTpl = $('<span />', {class: 'answer_indicator correct'})
    this.creditPartialTpl = $('<span />', {class: 'answer_indicator incorrect'})
    this.creditNoneTpl = $('<span />', {class: 'answer_indicator incorrect'})

    this.unansweredTpl = $('<span />', {class: 'answer_indicator incorrect'})
    this.answeredCorrectTpl = $('<span />', {class: 'answer_indicator correct'})
    this.answeredIncorrectTpl = $('<span />', {class: 'answer_indicator incorrect'})

    this.surveyAnswerTpl = $('<span />', {class: 'answer_arrow info'})
    this.surveyAnswers = $('#questions.survey_results .selected_answer')
  }

  applyCorrectAndIncorrectArrows() {
    this.rightTpl.attr('aria-label', I18n.t('answers.correct', 'Correct!'))
    this.wrongTpl.attr('aria-label', I18n.t('answers.you_answered', 'You Answered'))
    this.correctTpl.attr('aria-label', I18n.t('answers.right', 'Correct Answer'))

    this.rightAnswers.prepend(this.rightTpl)
    this.wrongAnswers.prepend(this.wrongTpl)
    this.correctAnswers.prepend(this.correctTpl)

    this.shortTpl.text(I18n.t('answers.correct_answers', 'Correct Answers'))

    // without .clone(), last correctTpl instance (in correctAnswers)
    //   will be moved to editableMatches/readOnlyMatches(if any)
    this.editableMatches.parent().before(this.correctTpl.clone())
    this.readOnlyMatches.prepend(this.correctTpl.clone())
    this.shortAnswers.prepend(this.shortTpl)
  }

  applyAnsweredAndUnansweredArrows() {
    this.unansweredTpl.text(I18n.t('answers.unanswered', 'Unanswered'))
    this.unansweredQ.prepend(this.unansweredTpl)
    this.unansweredQ.addClass('bordered')

    this.answeredCorrectTpl.text(I18n.t('answers.answered_correct', 'Correct answer'))
    this.answeredIncorrectTpl.text(I18n.t('answers.answered_incorrect', 'Wrong answer'))

    this.creditFullTpl.text(I18n.t('answers.correct', 'Correct!'))
    this.creditPartialTpl.text(I18n.t('answers.partial', 'Partial'))
    this.creditNoneTpl.text(I18n.t('answers.incorrect', 'Incorrect'))

    if (ENV.IS_SURVEY) {
      this.surveyAnswerTpl.attr('aria-label', I18n.t('answers.you_answered', 'You Answered'))
      this.surveyAnswers.prepend(this.surveyAnswerTpl)
    } else {
      if (this.supressAnswers) {
        this.creditFull.prepend(this.creditFullTpl)
        this.creditPartial.prepend(this.creditPartialTpl)
        this.creditNone.prepend(this.creditNoneTpl)

        this.creditFull.addClass('bordered')
        this.creditPartial.addClass('bordered')
        this.creditNone.addClass('bordered')
      } else {
        this.answeredCorrectQ.prepend(this.answeredCorrectTpl)
        this.answeredIncorrectQ.prepend(this.answeredIncorrectTpl)

        this.answeredCorrectQ.addClass('bordered')
        this.answeredIncorrectQ.addClass('bordered')
      }
    }
  }

  makeArrowsAccessible() {
    // adjust these down a little so they align better w/ answers.
    $('.short_answer_question .answer_arrow').css('top', 5)

    // CNVS-6634:
    //
    // Enable a11y for <input /> elements that receive focus by speaking the
    // answer result which is contained in the arrow marker.
    $('#questions .answer_arrow, #questions .answer_indicator').each(function () {
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

  applyArrows() {
    if (!ENV.IS_SURVEY) this.applyCorrectAndIncorrectArrows()
    this.applyAnsweredAndUnansweredArrows()
    this.makeArrowsAccessible()
  }
}
