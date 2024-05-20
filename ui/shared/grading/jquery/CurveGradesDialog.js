/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import $ from 'jquery'
import curveGradesDialogTemplate from '../jst/CurveGradesDialog.handlebars'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/util/jquery/fixDialogButtons'
import 'jquery-tinypubsub'

const I18n = useI18nScope('sharedCurveGradesDialog')

export default (function () {
  function CurveGradesDialog(arg) {
    this.assignment = arg.assignment
    this.students = arg.students
    this.context_url = arg.context_url
    this.curve = this.curve.bind(this)
    this.show = this.show.bind(this)
  }

  CurveGradesDialog.prototype.show = function (onClose) {
    const locals = {
      assignment: this.assignment,
      action: this.context_url + '/gradebook/update_submission',
      middleScore: I18n.n((this.assignment.points_possible || 0) * 0.6),
      showOutOf: this.assignment.points_possible >= 0,
      formattedOutOf: I18n.n(this.assignment.points_possible),
    }
    this.$dialog = $(curveGradesDialogTemplate(locals))
    this.$dialog
      .formSubmit({
        disableWhileLoading: true,
        processData: (function (_this) {
          return function (data) {
            let cnt, errorBox, idx, percent, pre
            if (!_this.assignment.points_possible || _this.assignment.points_possible === '0') {
              errorBox = _this.$dialog.errorBox(
                I18n.t('errors.no_points_possible', 'Cannot curve without points possible')
              )
              setTimeout(function () {
                return errorBox.fadeOut(function () {
                  return errorBox.remove()
                })
              }, 3500)
              return false
            }
            cnt = 0
            const curves = _this.curve()
            for (idx in curves) {
              pre = 'submissions[submission_' + idx + ']'
              data[pre + '[assignment_id]'] = data.assignment_id
              data[pre + '[user_id]'] = idx
              if (
                _this.assignment.grading_type === 'gpa_scale' ||
                _this.assignment.grading_type === 'percent'
              ) {
                percent = (curves[idx] / _this.assignment.points_possible) * 100
                data[pre + '[grade]'] =
                  '' +
                  I18n.n(percent, {
                    percentage: true,
                  })
              } else {
                data[pre + '[grade]'] = curves[idx]
              }
              cnt++
            }
            if (cnt === 0) {
              errorBox = _this.$dialog.errorBox(I18n.t('errors.none_to_update', 'None to Update'))
              setTimeout(function () {
                return errorBox.fadeOut(function () {
                  return errorBox.remove()
                })
              }, 3500)
              return false
            }
            return data
          }
        })(this),
        success: (function (_this) {
          return function (data) {
            let datum
            _this.$dialog.dialog('close')
            const submissions = (function () {
              let i, len
              const results = []
              for (i = 0, len = data.length; i < len; i++) {
                datum = data[i]
                results.push(datum.submission)
              }
              return results
            })()
            $.publish('submissions_updated', [submissions])
            // eslint-disable-next-line no-alert
            window.alert(
              I18n.t(
                {
                  one: '1 Student score updated',
                  other: '%{studentCount} Student scores updated',
                },
                {
                  count: data.length,
                  studentCount: I18n.n(data.length),
                }
              )
            )
            return $('#set_default_grade').focus()
          }
        })(this),
      })
      .dialog({
        width: 350,
        modal: true,
        resizable: false,
        open: this.curve,
        close: (function (_this) {
          return function () {
            return _this.$dialog.remove()
          }
        })(this),
        zIndex: 1000,
      })
      .fixDialogButtons()
    this.$dialog.on('dialogclose', onClose)
    this.$dialog.parent().find('.ui-dialog-titlebar-close').focus()
    this.$dialog.find('#middle_score').bind('blur change keyup focus', this.curve)
    return this.$dialog.find('#assign_blanks').change(this.curve)
  }

  CurveGradesDialog.prototype.curve = function () {
    let cnt,
      color,
      currentBreak,
      finalScore,
      i,
      idx,
      len,
      maxCount,
      pct,
      score,
      scoreCount,
      skipCount,
      student,
      sub,
      tally,
      title,
      user,
      users
    idx = 0
    const users_for_score = []
    scoreCount = 0
    let middleScore = numberHelper.parse($('#middle_score').val())
    middleScore /= this.assignment.points_possible
    const should_assign_blanks = $('#assign_blanks').prop('checked')
    // eslint-disable-next-line no-restricted-globals
    if (isNaN(middleScore)) {
      return
    }
    const ref = this.students
    for (idx in ref) {
      student = ref[idx]
      sub = student['assignment_' + this.assignment.id]
      // eslint-disable-next-line no-void
      score = sub != null ? sub.score : void 0
      if (score > this.assignment.points_possible) {
        score = this.assignment.points_possible
      }
      if (score < 0 || (score == null && should_assign_blanks)) {
        score = 0
      }
      users_for_score[parseInt(score, 10)] = users_for_score[parseInt(score, 10)] || []
      users_for_score[parseInt(score, 10)].push([idx, score || 0])
      scoreCount++
    }
    const breaks = [
      0.006, 0.012, 0.028, 0.04, 0.068, 0.106, 0.159, 0.227, 0.309, 0.401, 0.5, 0.599, 0.691, 0.773,
      0.841, 0.894, 0.933, 0.96, 0.977, 0.988, 1.0,
    ]
    const interval = (1.0 - middleScore) / Math.floor(breaks.length / 2)
    const breakScores = []
    const breakPercents = []
    idx = 0
    while (idx < breaks.length) {
      breakPercents.push(1.0 - interval * idx)
      breakScores.push(Math.round((1.0 - interval * idx) * this.assignment.points_possible))
      idx++
    }
    tally = 0
    const finalScores = {}
    currentBreak = 0
    $('#results_list').empty()
    $('#results_values').empty()
    const final_users_for_score = []
    idx = users_for_score.length - 1
    while (idx >= 0) {
      users = users_for_score[idx] || []
      score = Math.round(breakScores[currentBreak])
      for (i = 0, len = users.length; i < len; i++) {
        user = users[i]
        finalScores[user[0]] = score
        if (user[1] === 0) {
          finalScores[user[0]] = 0
        }
        finalScore = finalScores[user[0]]
        final_users_for_score[finalScore] = final_users_for_score[finalScore] || []
        final_users_for_score[finalScore].push(user[0])
      }
      tally += users.length
      while (tally > breaks[currentBreak] * scoreCount) {
        currentBreak++
      }
      idx--
    }
    maxCount = 0
    idx = final_users_for_score.length - 1
    while (idx >= 0) {
      cnt = (final_users_for_score[idx] || []).length
      if (cnt > maxCount) {
        maxCount = cnt
      }
      idx--
    }
    const width = 15
    skipCount = 0
    idx = final_users_for_score.length - 1
    while (idx >= 0) {
      users = final_users_for_score[idx]
      pct = 0
      cnt = 0
      if (users || skipCount > this.assignment.points_possible / 10) {
        if (users) {
          pct = users.length / maxCount
          cnt = users.length
        }
        color = idx === 0 ? '#a03536' : '#007ab8'
        title = I18n.t(
          {
            one: '1 student will get %{num} points',
            other: '%{studentCount} students will get %{num} points',
          },
          {
            count: cnt,
            num: I18n.n(idx),
            studentCount: I18n.n(cnt),
          }
        )
        $('#results_list').prepend(
          "<td style='padding: 1px;'><div title='" +
            htmlEscape(title) +
            "' style='border: 1px solid #888; background-color: " +
            htmlEscape(color) +
            '; width: ' +
            htmlEscape(width) +
            'px; height: ' +
            htmlEscape(100 * pct) +
            'px; margin-top: ' +
            htmlEscape(100 * (1 - pct)) +
            "px;'>&nbsp;</div></td>"
        )
        $('#results_values').prepend(
          "<td style='text-align: center;'>" + htmlEscape(I18n.n(idx)) + '</td>'
        )
        skipCount = 0
      } else {
        skipCount++
      }
      idx--
    }
    $('#results_list').prepend(
      "<td><div style='height: 100px; position: relative; width: 30px; font-size: 0.8em;'>" +
        "<img src='/images/number_of_students.png' alt='" +
        htmlEscape(I18n.t('# of students')) +
        "'/><div style='position: absolute; top: 0; right: 3px;'>" +
        htmlEscape(I18n.n(maxCount)) +
        "</div><div style='position: absolute; bottom: 0; right: 3px;'>" +
        htmlEscape(I18n.n(0)) +
        '</div></div></td>'
    )
    $('#results_values').prepend('<td>&nbsp;</td>')
    return finalScores
  }

  return CurveGradesDialog
})()
