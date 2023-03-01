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

import React from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from 'html-escape'

const I18n = useI18nScope('speed_grader_helpers')

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

export function setupIsModerated({moderated_grading}) {
  return moderated_grading
}

export function setupIsAnonymous({anonymize_students}) {
  return anonymize_students
}

export function setupAnonymousGraders({anonymize_graders}) {
  return anonymize_graders
}

export function setupAnonymizableId(isAnonymous) {
  return isAnonymous ? 'anonymous_id' : 'id'
}

export function setupAnonymizableStudentId(isAnonymous) {
  return isAnonymous ? 'anonymous_id' : 'student_id'
}

export function setupAnonymizableUserId(isAnonymous) {
  return isAnonymous ? 'anonymous_id' : 'user_id'
}

export function setupAnonymizableAuthorId(isAnonymous) {
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

export const configureRecognition = (recognition, messages) => {
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

export function initKeyCodes($window, $grade, $add_a_comment_textarea, EG) {
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

export function renderStatusMenu(component, mountPoint) {
  const unmountPoint =
    mountPoint.id === SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT
      ? SPEED_GRADER_EDIT_STATUS_MENU_SECONDARY_MOUNT_POINT
      : SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT
  ReactDOM.render(<></>, document.getElementById(unmountPoint))
  ReactDOM.render(component, mountPoint)
}

export function plagiarismResubmitButton(hasOriginalityScore, buttonContainer) {
  if (hasOriginalityScore) {
    buttonContainer.hide()
  } else {
    buttonContainer.show()
  }
}
