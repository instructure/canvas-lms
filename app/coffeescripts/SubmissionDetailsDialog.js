import $ from 'jquery'
import submissionDetailsDialog from 'jst/SubmissionDetailsDialog'
import I18n from 'i18n!submission_details_dialog'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'
import GradebookHelpers from './gradebook/GradebookHelpers'
import {extractDataForTurnitin} from './gradebook/Turnitin'
import OutlierScoreHelper from 'jsx/grading/helpers/OutlierScoreHelper'
import 'jst/_submission_detail' // a partial needed by the SubmissionDetailsDialog template
import 'jst/_turnitinScore' // a partial needed by the submission_detail partial
import 'jquery.ajaxJSON'
import 'jquery.disableWhileLoading'
import 'jquery.instructure_forms'
import 'jqueryui/dialog'
import 'jquery.instructure_misc_plugins'
import 'vendor/jquery.scrollTo'
import 'vendor/jquery.ba-tinypubsub'


export default class SubmissionDetailsDialog {
  constructor (assignment, student, options) {
    this.assignment = assignment
    this.student = student
    this.options = options
    const speedGraderUrl = this.options.speed_grader_enabled
      ? this.buildSpeedGraderUrl()
      : null

    this.url = this.options.change_grade_url.replace(':assignment', this.assignment.id).replace(':submission', this.student.id)
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
      isInPastGradingPeriodAndNotAdmin: submission.gradeLocked
    })
    this.submission[`assignment_grading_type_is_${this.assignment.grading_type}`] = true
    if (this.submission.excused) this.submission.grade = 'EX'
    this.$el = $('<div class="use-css-transitions-for-show-hide" style="padding:0;"/>')
    this.$el.html(submissionDetailsDialog(this.submission))

    this.dialog = this.$el.dialog({
      title: this.student.name,
      width: 600,
      resizable: false
    })

    this.dialog.on('dialogclose', this.options.onClose)
    this.dialog.on('dialogclose', () => {
      this.dialog.dialog('destroy')
      this.$el.remove()
    })
    this.dialog
      .delegate('select[id="submission_to_view"]', 'change', event => this.dialog.find('.submission_detail').each(function (index) {
        $(this).showIf(index === event.currentTarget.selectedIndex)
      }))
      .delegate('.submission_details_grade_form', 'submit', (event) => {
        event.preventDefault()
        let formData = $(event.currentTarget).getFormData()
        const rawGrade = formData['submission[posted_grade]']
        if (rawGrade.toUpperCase() === 'EX') {
          formData = {'submission[excuse]': true}
        } else {
          formData['submission[posted_grade]'] = GradeFormatHelper.delocalizeGrade(rawGrade)
        }
        $(event.currentTarget.form).disableWhileLoading(
          $.ajaxJSON(this.url, 'PUT', formData, (data) => {
            this.update(data)
            if (!data.excused) {
              const outlierScoreHelper = new OutlierScoreHelper(this.submission.score, this.submission.assignment.points_possible)
              if (outlierScoreHelper.hasWarning()) {
                $.flashWarning(outlierScoreHelper.warningMessage())
              }
            }
            $.publish('submissions_updated', [this.submission.all_submissions])
            setTimeout(() => this.dialog.dialog('close'), 500)
          })
        )
      })
      .delegate('.submission_details_add_comment_form', 'submit', (event) => {
        event.preventDefault()
        $(event.currentTarget).disableWhileLoading(
          $.ajaxJSON(this.url, 'PUT', $(event.currentTarget).getFormData(), (data) => {
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
      : `${assignmentParam}#{"student_id":"${this.student.id}"}`
    return encodeURI(`${this.options.context_url}/gradebook/speed_grader?${speedGraderUrlParams}`)
  }

  open = () => {
    this.dialog.dialog('open')
    this.scrollCommentsToBottom()
    $('.ui-dialog-titlebar-close').focus()
  }

  scrollCommentsToBottom = () =>
    this.dialog.find('.submission_details_comments').scrollTop(999999)


  update = (newData) => {
    $.extend(this.submission, newData)
    this.submission.moreThanOneSubmission = this.submission.submission_history.length > 1
    this.submission.loading = false
    this.submission.submission_history.forEach((submission) => {
      submission.submission_comments && submission.submission_comments.forEach((comment) => {
        comment.url = `${this.options.context_url}/users/${comment.author_id}`
        const urlPrefix = `${location.protocol}//${location.host}`
        comment.image_url = `${urlPrefix}/images/users/${comment.author_id}`
      })
      submission.turnitin = extractDataForTurnitin(submission, `submission_${submission.id}`, this.options.context_url)
      submission.attachments && submission.attachments.forEach((attachment) => {
        attachment.turnitin = extractDataForTurnitin(submission, `attachment_${attachment.id}`, this.options.context_url)
      })
    })

    if (this.options.anonymous) {
      this.submission.submission_comments.forEach((comment) => {
        if(comment.author.id !== ENV.current_user_id) {
          comment.anonymous = comment.author.anonymous = true;
          comment.author_name = I18n.t('Student');
        }
      });
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

  static open (assignment, student, options) {
    return new SubmissionDetailsDialog(assignment, student, options).open()
  }
}
