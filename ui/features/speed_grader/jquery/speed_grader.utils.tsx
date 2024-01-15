// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import type JQuery from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import SpeedGraderSettingsMenu from '../react/SpeedGraderSettingsMenu'
import htmlEscape from '@instructure/html-escape'
import {Pill} from '@instructure/ui-pill'
import * as Alerts from '@instructure/ui-alerts'
import type {RubricAssessment} from '@canvas/grading/grading.d'
import type {
  Enrollment,
  GradingError,
  SpeedGrader,
  Submission,
  StudentWithSubmission,
} from './speed_grader.d'
import SpeedGraderPostGradesMenu from '../react/SpeedGraderPostGradesMenu'
import {isGraded, isPostable} from '@canvas/grading/SubmissionHelper'
import JQuerySelectorCache from '../JQuerySelectorCache'

const selectors = new JQuerySelectorCache()

const I18n = useI18nScope('speed_grader_helpers')

const {Alert} = Alerts as any

export const SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT = 'speed_grader_comment_textarea_mount_point'
export const SPEED_GRADER_SUBMISSION_COMMENTS_DOWNLOAD_MOUNT_POINT =
  'speed_grader_submission_comments_download_mount_point'
export const SPEED_GRADER_POST_GRADES_MENU_MOUNT_POINT = 'speed_grader_post_grades_menu_mount_point'
export const SPEED_GRADER_SETTINGS_MOUNT_POINT = 'speed_grader_settings_mount_point'
export const SPEED_GRADER_HIDDEN_SUBMISSION_PILL_MOUNT_POINT =
  'speed_grader_hidden_submission_pill_mount_point'
export const SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT = 'speed_grader_edit_status_mount_point'
export const SPEED_GRADER_EDIT_STATUS_MENU_SECONDARY_MOUNT_POINT =
  'speed_grader_edit_status_secondary_mount_point'
export const ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT =
  'speed_grader_assessment_audit_button_mount_point'
export const ASSESSMENT_AUDIT_TRAY_MOUNT_POINT = 'speed_grader_assessment_audit_tray_mount_point'

export function setupIsModerated({moderated_grading}: {moderated_grading: boolean}) {
  return moderated_grading
}

export function setupIsAnonymous({anonymize_students}: {anonymize_students: boolean}) {
  return Boolean(anonymize_students)
}

export function setupAnonymousGraders({anonymize_graders}: {anonymize_graders: boolean}) {
  return Boolean(anonymize_graders)
}

export function setupAnonymizableId(isAnonymous: boolean) {
  return isAnonymous ? 'anonymous_id' : 'id'
}

export function setupAnonymizableStudentId(isAnonymous: boolean) {
  return isAnonymous ? 'anonymous_id' : 'student_id'
}

export function setupAnonymizableUserId(isAnonymous: boolean) {
  return isAnonymous ? 'anonymous_id' : 'user_id'
}

export function setupAnonymizableAuthorId(isAnonymous: boolean) {
  return isAnonymous ? 'anonymous_id' : 'author_id'
}

export function extractStudentIdFromHash(hashString: string, anonymizableStudentId: string) {
  let studentId

  try {
    // The hash, if present, will be of the form '#{"student_id": "12"}';
    // remove the first character and parse the rest
    const hash = JSON.parse(decodeURIComponent(hashString.substr(1)))
    studentId = hash[anonymizableStudentId].toString()
  } catch (_error) {
    studentId = null
  }

  return studentId
}

export const configureRecognition = (
  recognition: {
    continuous: boolean
    interimResults: boolean
    lang: string
    onstart: () => void
    onresult: (event: {resultIndex: number; results: any[]}) => void
    onaudiostart: (event: any) => void
    onaudioend: (event: any) => void
    onend: (event: any) => void
    onerror: (event: {error: string}) => void
  },
  messages: {
    recording: string
    recording_expired: string
    mic_blocked: string
    no_speech: string
  }
) => {
  recognition.continuous = true
  recognition.interimResults = true
  const lang = window.navigator.language || ENV.LOCALE || ENV.BIGEASY_LOCALE
  if (lang) {
    recognition.lang = lang
  }
  let final_transcript = ''

  recognition.onstart = function () {
    $('#dialog_message').text(messages.recording)
    $('#record_button')
      .attr('recording', 'true')
      .attr('aria-label', I18n.t('dialog_button.aria_stop', 'Hit "Stop" to end recording.'))
  }

  recognition.onresult = function (event) {
    let interim_transcript = ''
    for (let i = event.resultIndex; i < event.results.length; i++) {
      if (event.results[i].isFinal) {
        final_transcript += event.results[i][0].transcript
        $('#final_results').html(linebreak(final_transcript))
      } else {
        interim_transcript += event.results[i][0].transcript
      }
      $('#interim_results').html(linebreak(interim_transcript))
    }
  }

  recognition.onaudiostart = function (_event) {
    // this call is required for onaudioend event to trigger
  }

  recognition.onaudioend = function (_event) {
    if ($('#final_results').text() !== '' || $('#interim_results').text() !== '') {
      $('#dialog_message').text(messages.recording_expired)
    }
  }

  recognition.onend = function (_event) {
    final_transcript = ''
  }

  recognition.onerror = function (event) {
    if (event.error === 'not-allowed') {
      $('#dialog_message').text(messages.mic_blocked)
    } else if (event.error === 'no-speech') {
      $('#dialog_message').text(messages.no_speech)
    }
    $('#record_button')
      .attr('recording', 'false')
      .attr('aria-label', I18n.t('dialog_button.aria_record_reset', 'Click to record'))
  }

  // xsslint safeString.function linebreak
  function linebreak(transcript: string) {
    return htmlEscape(transcript).replace(/\n\n/g, '<p></p>').replace(/\n/g, '<br>')
  }
}

export function buildAlertMessage() {
  let alertMessage
  if (
    ENV.filter_speed_grader_by_student_group_feature_enabled &&
    !ENV.filter_speed_grader_by_student_group
  ) {
    alertMessage = I18n.t(
      'Something went wrong. Please try refreshing the page. If the problem persists, you can try loading a single student group in SpeedGrader by using the *Large Course setting*.',
      {wrappers: [`<a href="/courses/${ENV.course_id}/settings#course_large_course">$1</a>`]}
    ).string
  } else {
    alertMessage = I18n.t('Something went wrong. Please try refreshing the page.')
  }
  return {__html: alertMessage}
}

export function initKeyCodes(
  $window: JQuery,
  $grade: JQuery,
  $add_a_comment_textarea: JQuery,
  EG: SpeedGrader
) {
  if (ENV.disable_keyboard_shortcuts) {
    return
  }
  const keycodeOptions = {
    keyCodes: 'j k p n c r g',
    ignore: 'input, textarea, embed, object',
  }
  $window.keycodes(keycodeOptions, event => {
    event.preventDefault()
    event.stopPropagation()
    const {keyString} = event

    if (keyString === 'k' || keyString === 'p') {
      EG.prev() // goto Previous Student
    } else if (keyString === 'j' || keyString === 'n') {
      EG.next() // goto Next Student
    } else if (keyString === 'c') {
      $add_a_comment_textarea.focus() // add comment
    } else if (keyString === 'g') {
      $grade.focus() // focus on grade
    } else if (keyString === 'r') {
      EG.toggleFullRubric() // focus rubric
    }
  })
}

export function renderStatusMenu(component: React.ReactElement | null, mountPoint: HTMLElement) {
  const unmountPoint =
    mountPoint.id === SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT
      ? SPEED_GRADER_EDIT_STATUS_MENU_SECONDARY_MOUNT_POINT
      : SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT
  ReactDOM.render(<></>, document.getElementById(unmountPoint))
  ReactDOM.render(component || <></>, mountPoint)
}

export function plagiarismResubmitButton(hasOriginalityScore: boolean, buttonContainer: JQuery) {
  if (hasOriginalityScore) {
    buttonContainer.hide()
  } else {
    buttonContainer.show()
  }
}

// anonymous_name is preferred and will be available for all anonymous
// assignments. Fall back to naming based on index for assignments that are not
// anonymous, but the teacher has selected to 'Hide Student Names' in SpeedGrader.
export function anonymousName(student: StudentWithSubmission): string {
  return student.anonymous_name || I18n.t('Student %{number}', {number: student.index + 1})
}

export function unmountCommentTextArea() {
  const node = document.getElementById(SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT)
  if (!node) throw new Error('comment textarea mount point not found')
  ReactDOM.unmountComponentAtNode(node)
}

export function teardownSettingsMenu() {
  const mountPoint = document.getElementById(SPEED_GRADER_SETTINGS_MOUNT_POINT)
  if (!mountPoint) throw new Error('could not find mount point for settings menu')
  ReactDOM.unmountComponentAtNode(mountPoint)
}

export function tearDownAssessmentAuditTray(EG: SpeedGrader) {
  const mount1 = document.getElementById(ASSESSMENT_AUDIT_TRAY_MOUNT_POINT)
  if (mount1) ReactDOM.unmountComponentAtNode(mount1)
  const mount2 = document.getElementById(ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT)
  if (mount2) ReactDOM.unmountComponentAtNode(mount2)
  EG.assessmentAuditTray = null
}

export function unexcuseSubmission(grade: string, submission: Submission, assignment: unknown) {
  return grade === '' && submission.excused && assignment.grading_type === 'pass_fail'
}

export function renderPostGradesMenu(EG: SpeedGrader) {
  const {submissionsMap} = window.jsonData
  const submissions = window.jsonData.studentsWithSubmissions.map(
    (student: StudentWithSubmission) => student.submission
  )

  const hasGradesOrPostableComments = submissions.some(
    (submission: Submission) =>
      submission && (isGraded(submission) || submission.has_postable_comments)
  )
  const allowHidingGradesOrComments = submissions.some(
    (submission: Submission) => submission && submission.posted_at != null
  )
  const allowPostingGradesOrComments = submissions.some(
    (submission: Submission) => submission && isPostable(submission)
  )

  function onHideGrades() {
    EG.postPolicies?.showHideAssignmentGradesTray({submissionsMap, submissions})
  }

  function onPostGrades() {
    EG.postPolicies?.showPostAssignmentGradesTray({submissionsMap, submissions})
  }

  const props = {
    allowHidingGradesOrComments,
    allowPostingGradesOrComments,
    hasGradesOrPostableComments,
    onHideGrades,
    onPostGrades,
  }

  ReactDOM.render(
    <SpeedGraderPostGradesMenu {...props} />,
    document.getElementById(SPEED_GRADER_POST_GRADES_MENU_MOUNT_POINT)
  )
}

export function hideMediaRecorderContainer() {
  $('#media_media_recording').hide().removeData('comment_id').removeData('comment_type')
}

export function renderHiddenSubmissionPill(submission: Submission) {
  const mountPoint = document.getElementById(SPEED_GRADER_HIDDEN_SUBMISSION_PILL_MOUNT_POINT)
  if (!mountPoint) throw new Error('hidden submission pill mount point not found')

  if (isPostable(submission)) {
    ReactDOM.render(
      <Pill color="warning" margin="0 0 small">
        {I18n.t('Hidden')}
      </Pill>,
      mountPoint
    )
  } else {
    ReactDOM.unmountComponentAtNode(mountPoint)
  }
}

export function toggleGradeVisibility(show: boolean): void {
  const gradeInput = $('#grading')
  if (show) {
    gradeInput.show().height('auto')
  } else {
    gradeInput.hide()
  }
}

export function allowsReassignment(submission: Submission) {
  const reassignableTypes = [
    'media_recording',
    'online_text_entry',
    'online_upload',
    'online_url',
    'student_annotation',
  ]

  return (
    submission.cached_due_date != null &&
    reassignableTypes.includes(submission.submission_type as string)
  )
}

export function renderDeleteAttachmentLink(
  $submission_file: JQuery,
  attachment: {
    display_name: string
  }
) {
  const $full_width_container = $('#full_width_container')

  if (ENV.can_delete_attachments) {
    const $delete_link = $submission_file.find('a.submission-file-delete')
    $delete_link.click(function (this: HTMLElement, event: JQuery.ClickEvent) {
      event.preventDefault()
      const url = $(this).attr('href')
      if (!url) throw new Error('submission-file-delete href not found')
      if (
        // eslint-disable-next-line no-alert
        window.confirm(
          I18n.t(
            'Deleting a submission file is typically done only when a student posts inappropriate or private material.\n\nThis action is irreversible. Are you sure you wish to delete %{file}?',
            {file: attachment.display_name}
          )
        )
      ) {
        $full_width_container.disableWhileLoading(
          $.ajaxJSON(
            url,
            'DELETE',
            {},
            (_data: unknown) => {
              // a more targeted refresh would be preferable but this works (and `EG.showSubmission()` doesn't)
              window.location.reload()
            },
            (data: {status: string}) => {
              if (data.status === 'unauthorized') {
                $.flashError(
                  I18n.t(
                    'You do not have permission to delete %{file}. Please contact your account administrator.',
                    {file: attachment.display_name}
                  )
                )
              } else {
                $.flashError(I18n.t('Error deleting %{file}', {file: attachment.display_name}))
              }
            }
          )
        )
      }
    })
    $delete_link.show()
  }
}

export function isAssessmentEditableByMe(assessment: {
  assessor_id: string
  assessment_type: string
}) {
  // if the assessment is mine or I can :manage_grades then it is editable
  if (
    !assessment ||
    assessment.assessor_id === ENV.RUBRIC_ASSESSMENT.assessor_id ||
    (ENV.RUBRIC_ASSESSMENT.assessment_type === 'grading' &&
      assessment.assessment_type === 'grading')
  ) {
    return true
  }
  return false
}

export function teardownHandleStatePopped(EG: SpeedGrader) {
  window.removeEventListener('popstate', EG.handleStatePopped)
}

export function renderSettingsMenu(header) {
  function showKeyboardShortcutsModal() {
    // need to place at end of execution queue to make focus work properly
    setTimeout(header.keyboardShortcutInfoModal.bind(header), 0)
  }

  function showOptionsModal() {
    // need to place at end of execution queue to make focus work properly
    setTimeout(header.showSettingsModal.bind(header), 0)
  }

  const props = {
    assignmentID: ENV.assignment_id,
    courseID: ENV.course_id,
    helpURL: ENV.help_url,
    openOptionsModal: showOptionsModal,
    openKeyboardShortcutsModal: showKeyboardShortcutsModal,
    showModerationMenuItem: ENV.grading_role === 'moderator',
    showHelpMenuItem: ENV.show_help_menu_item,
    showKeyboardShortcutsMenuItem: !ENV.disable_keyboard_shortcuts,
  }

  const mountPoint = document.getElementById(SPEED_GRADER_SETTINGS_MOUNT_POINT)
  ReactDOM.render(<SpeedGraderSettingsMenu {...props} />, mountPoint)
}

export function speedGraderJSONErrorFn(
  _data: GradingError,
  xhr: XMLHttpRequest,
  _textStatus: string,
  _errorThrown: Error
) {
  if (xhr.status === 504) {
    const alertProps = {
      variant: 'error',
      dismissible: false,
    }

    ReactDOM.render(
      <Alert {...alertProps}>
        <span dangerouslySetInnerHTML={buildAlertMessage()} />
      </Alert>,
      document.getElementById('speed_grader_timeout_alert')
    )
  }
}

export function getSelectedAssessment(EG) {
  const selectMenu = selectors.get('#rubric_assessments_select')

  return $.grep(
    EG.currentStudent.rubric_assessments,
    (n: RubricAssessment) => n.id === selectMenu.val()
  )[0]
}

export function rubricAssessmentToPopulate(EG) {
  const assessment = getSelectedAssessment(EG)
  const userIsNotAssessor = !!assessment && assessment.assessor_id !== ENV.current_user_id
  const userCanAssess = isAssessmentEditableByMe(assessment)

  if (userIsNotAssessor && !userCanAssess) {
    return {}
  }

  return assessment
}

export function isStudentConcluded(studentMap: any, student: string, sectionId: string | null) {
  if (!studentMap) {
    return false
  }

  // If we're in a section specific mode, we'll look to see if there are any concluded enrollments in this section. If
  // we're in the all sections mode, we only look concluded when ALL enrollments are concluded.
  if (sectionId) {
    return studentMap[student].enrollments.some(
      (enrollment: Enrollment) =>
        enrollment.workflow_state === 'completed' && enrollment.course_section_id === sectionId
    )
  } else {
    return studentMap[student].enrollments.every(
      (enrollment: Enrollment) => enrollment.workflow_state === 'completed'
    )
  }
}
