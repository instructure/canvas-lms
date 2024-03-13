/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import submissionDetailsDialog from '../jst/SubmissionDetailsDialog.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {originalityReportSubmissionKey} from '@canvas/grading/originalityReportHelper'
import {extractDataForTurnitin} from '@canvas/grading/Turnitin'
import OutlierScoreHelper from '@canvas/grading/OutlierScoreHelper'
import '../jst/_submission_detail.handlebars' // a partial needed by the SubmissionDetailsDialog template
import '@canvas/grading/jst/_turnitinScore.handlebars' // a partial needed by the submission_detail partial
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jquery-tinypubsub'

const I18n = useI18nScope('submission_details_dialog')

export default class SubmissionDetailsDialog {
  constructor(assignment, student, options) {
    this.assignment = assignment
    this.student = student
    this.options = options
    const speedGraderUrl = this.options.speed_grader_enabled ? this.buildSpeedGraderUrl() : null

    this.url = this.options.change_grade_url
      .replace(':assignment', this.assignment.id)
      .replace(':submission', this.student.id)
    const submission = this.student[`assignment_${this.assignment.id}`]
    this.submission = $.extend({}, submission, {
      label: `student_grading_${this.assignment.id}`,
      inputName: 'submission[posted_grade]',
      assignment: this.assignment,
      speedGraderUrl,
      loading: true,
      showPointsPossible:
        (this.assignment.points_possible || this.assignment.points_possible === '0') &&
        this.assignment.grading_type !== 'gpa_scale',
      formattedPointsPossible: I18n.n(this.assignment.points_possible),
      shouldShowExcusedOption: true,
      isInPastGradingPeriodAndNotAdmin: submission.gradeLocked,
    })
    this.submission[`assignment_grading_type_is_${this.assignment.grading_type}`] = true
    if (this.submission.excused) this.submission.grade = 'EX'
    this.$el = $('<div class="use-css-transitions-for-show-hide" style="padding:0;"/>')
    this.$el.html(submissionDetailsDialog(this.submission))

    this.dialog = this.$el.dialog({
      title: this.student.name,
      width: 600,
      resizable: false,
      modal: true,
      zIndex: 1000,
    })

    this.dialog.on('dialogclose', this.options.onClose)
    this.dialog.on('dialogclose', () => {
      this.dialog.dialog('destroy')
      this.$el.remove()
    })
    this.dialog
      .on('change', 'select[id="submission_to_view"]', event =>
        this.dialog.find('.submission_detail').each(function (index) {
          $(this).showIf(index === event.currentTarget.selectedIndex)
        })
      )
      .on('submit', '.submission_details_grade_form', event => {
        event.preventDefault()
        let formData = $(event.currentTarget).getFormData()
        const rawGrade = formData['submission[posted_grade]']
        if (rawGrade.toUpperCase() === 'EX') {
          formData = {'submission[excuse]': true}
        } else {
          formData['submission[posted_grade]'] = GradeFormatHelper.delocalizeGrade(rawGrade)
        }
        $(event.currentTarget.form).disableWhileLoading(
          $.ajaxJSON(this.url, 'PUT', formData, data => {
            this.update(data)
            if (!data.excused) {
              const outlierScoreHelper = new OutlierScoreHelper(
                this.submission.score,
                this.submission.assignment.points_possible
              )
              if (outlierScoreHelper.hasWarning()) {
                $.flashWarning(outlierScoreHelper.warningMessage())
              }
            }
            $.publish('submissions_updated', [this.submission.all_submissions])
            setTimeout(() => this.dialog.dialog('close'), 500)
          })
        )
      })
      .on('submit', '.submission_details_add_comment_form', event => {
        event.preventDefault()
        $(event.currentTarget).disableWhileLoading(
          $.ajaxJSON(this.url, 'PUT', $(event.currentTarget).getFormData(), data => {
            this.update(data)
            setTimeout(() => this.dialog.dialog('close'), 500)
          })
        )
      })

    const url = `${this.url}&include[]=submission_history&include[]=submission_comments&include[]=rubric_assessment`
    const deferred = $.ajaxJSON(url, 'GET', {}, this.update)
    this.dialog.find('.submission_details_comments').disableWhileLoading(deferred)
  }

  buildSpeedGraderUrl = () => {
    const assignmentParam = `assignment_id=${this.assignment.id}`
    const speedGraderUrlParams = this.assignment.anonymize_students
      ? assignmentParam
      : `${assignmentParam}&student_id=${this.student.id}`
    return encodeURI(`${this.options.context_url}/gradebook/speed_grader?${speedGraderUrlParams}`)
  }

  open = () => {
    this.dialog.dialog('open')
    this.scrollCommentsToBottom()
    $('.ui-dialog-titlebar-close').focus()
  }

  scrollCommentsToBottom = () => this.dialog.find('.submission_details_comments').scrollTop(999999)

  update = newData => {
    $.extend(this.submission, newData)
    this.submission.moreThanOneSubmission = this.submission.submission_history.length > 1
    this.submission.loading = false
    this.submission.submission_history.forEach(submission => {
      submission.submission_comments &&
        submission.submission_comments.forEach(comment => {
          comment.url = `${this.options.context_url}/users/${comment.author_id}`
          const urlPrefix = `${window.location.protocol}//${window.location.host}`
          comment.image_url = `${urlPrefix}/images/users/${comment.author_id}`
        })
      submission.turnitin = extractDataForTurnitin(
        submission,
        originalityReportSubmissionKey(submission),
        this.options.context_url
      )

      if (Object.keys(submission.turnitin).length === 0) {
        submission.turnitin = extractDataForTurnitin(
          submission,
          `submission_${submission.id}`,
          this.options.context_url
        )
      }

      submission.attachments &&
        submission.attachments.forEach(attachment => {
          attachment.turnitin = extractDataForTurnitin(
            submission,
            `attachment_${attachment.id}`,
            this.options.context_url
          )
        })
    })

    if (this.options.anonymous) {
      this.submission.submission_comments.forEach(comment => {
        if (comment.author.id !== ENV.current_user_id) {
          comment.anonymous = comment.author.anonymous = true
          comment.author_name = I18n.t('Student')
        }
      })
    }

    if (this.submission.excused) {
      this.submission.grade = 'EX'
    } else if (['points', 'percent'].includes(this.assignment.grading_type)) {
      this.submission.grade = GradeFormatHelper.formatGrade(this.submission.grade)
    }
    this.dialog.html(submissionDetailsDialog(this.submission))
    this.dialog.find('select').trigger('change')
    return this.scrollCommentsToBottom()
  }

  static open(assignment, student, options) {
    return new SubmissionDetailsDialog(assignment, student, options).open()
  }
}
