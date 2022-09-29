/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import $ from 'jquery'
import numberHelper from '@canvas/i18n/numberHelper'
import I18n from '@canvas/i18n'

export default class GradingForm {
  constructor(scoringSnapshot) {
    this.scoringSnapshot = scoringSnapshot
  }

  ensureSelectEventsFire() {
    $('input[type=text]').focus(function () {
      $(this).select()
    })
  }

  preventInsanity(onInputChange) {
    $('#update_history_form input.question_input').keydown(function (event) {
      // stop enter from submitting for on DOWN,
      // otherwise it can actually wreck a database
      // because of the uniqueness constraints on the versions
      // table
      if (event.keyCode === 13) {
        if (onInputChange) {
          onInputChange($(this))
        }
        event.preventDefault()
        event.stopImmediatePropagation()
        return false
      }
    })
    $('#update_history_form input.question_input').keyup(function (event) {
      if (event.keyCode === 13) {
        // still let it submit when you're done pressing enter
        $('#update_history_form').submit()
      }
    })
  }

  scrollToUpdatedQuestion(event, hash) {
    if (hash.indexOf('#question') === 0) {
      const id = hash.substring(10)
      this.scoringSnapshot.jumpToQuestion(id)
    }
  }

  updateSnapshotFor($question) {
    const question_id = $question.attr('id').substring(9) || null
    if (question_id) {
      const data = {}
      if (!ENV.GRADE_BY_QUESTION) {
        $question.addClass('modified_but_not_saved')
      }
      data.points = numberHelper.parse($question.find('.user_points :text').val())
      data.comments =
        $question.find('.question_neutral_comment .question_comment_text textarea').val() || ''
      this.scoringSnapshot.update(question_id, data)
    }
    $(document).triggerHandler('score_changed')
  }

  addFudgePoints(points) {
    if (points || points === 0) {
      this.scoringSnapshot.snapshot.fudge_points = points
      this.scoringSnapshot.setSnapshot()
    }
    $(document).triggerHandler('score_changed')
  }

  setInitialSnapshot(data) {
    $('#feel_free_to_toggle_message').show()
    if (data) {
      this.scoringSnapshot.setSnapshot(data)
    } else {
      this.scoringSnapshot.setSnapshot(null, true)
    }
  }

  onScoreChanged() {
    const $total = $('#after_fudge_points_total')
    let total = 0
    $('.display_question .user_points:visible').each(function () {
      let points = numberHelper.parse($(this).find('input.question_input').val()) || 0
      points = Math.round(points * 100.0) / 100.0
      total += points
    })
    let fudge = numberHelper.parse($('#fudge_points_entry').val()) || 0
    fudge = Math.round(fudge * 100.0) / 100.0
    total += fudge
    $total.text(I18n.n(total) || '0')
  }

  questions() {
    return $('.question_holder')
      .map((index, el) => $(el).position().top - 320)
      .toArray()
  }

  onWindowResize() {
    // Add padding to the bottom of the last question
    const winHeight = $(window).innerHeight()
    const lastHeight = $('div.question_holder:last-child').outerHeight()
    const fixedButtonHeight = $('#speed_update_scores_container').outerHeight()
    const paddingHeight = Math.max(winHeight - lastHeight - 150, fixedButtonHeight)
    $('#update_history_form .quiz-submission.headless').css('marginBottom', paddingHeight + 'px')
  }
}
