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
import _ from 'underscore'
import I18n from 'i18n!speed_grader_helpers'
import '@canvas/datetime'
import '@canvas/jquery/jquery.instructure_misc_helpers'

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

const speedGraderHelpers = {
  getHistory() {
    return window.history
  },

  getLocation() {
    return document.location
  },

  getLocationHash() {
    return document.location.hash
  },

  setLocation(url) {
    document.location = url
  },

  setLocationHash(hash) {
    document.location.hash = hash
  },

  urlContainer(submission, defaultEl, originalityReportEl) {
    if (submission.has_originality_report) {
      return originalityReportEl
    }
    return defaultEl
  },

  buildIframe(src, options = {}, domElement = 'iframe') {
    const parts = [`<${domElement}`]
    parts.push(' id="speedgrader_iframe"')
    parts.push(` src="${src}"`)
    Object.keys(options).forEach(option => {
      let key = option
      const value = options[key]
      if (key === 'className') {
        key = 'class'
      }
      parts.push(` ${key}="${value}"`)
    })
    parts.push(`></${domElement}>`)
    return parts.join('')
  },

  determineGradeToSubmit(use_existing_score, student, grade) {
    if (use_existing_score) {
      return student.submission.score.toString()
    }
    return grade.val()
  },

  iframePreviewVersion(submission) {
    // check if the submission object is valid
    if (submission == null) {
      return ''
    }
    // check if the index is valid (multiple submissions)
    const currentSelectedIndex = submission.currentSelectedIndex
    if (currentSelectedIndex == null || isNaN(currentSelectedIndex)) {
      return ''
    }
    const select = '&version='
    // check if the version is valid, or matches the index
    const version = submission.submission_history[currentSelectedIndex].submission.version
    if (version == null || isNaN(version)) {
      return select + currentSelectedIndex
    }
    return select + version
  },

  resourceLinkLookupUuidParam(submission) {
    const resourceLinkLookupUuid = submission.resource_link_lookup_uuid

    if (resourceLinkLookupUuid) {
      return `&resource_link_lookup_uuid=${resourceLinkLookupUuid}`
    }

    return ''
  },

  setRightBarDisabled(isDisabled) {
    const elements = [
      '#grading-box-extended',
      '#speed_grader_comment_textarea',
      '#add_attachment',
      '#media_comment_button',
      '#comment_submit_button',
      '#speech_recognition_button'
    ]

    _.each(elements, element => {
      if (isDisabled) {
        $(element).addClass('ui-state-disabled')
        $(element).attr('aria-disabled', true)
        $(element).attr('readonly', true)
        $(element).prop('disabled', true)
      } else {
        $(element).removeClass('ui-state-disabled')
        $(element).removeAttr('aria-disabled')
        $(element).removeAttr('readonly')
        $(element).removeProp('disabled')
      }
    })
  },

  classNameBasedOnStudent(student) {
    const raw = student.submission_state
    let formatted
    switch (raw) {
      case 'graded':
      case 'not_gradeable':
        formatted = I18n.t('graded', 'graded')
        break
      case 'not_graded':
        formatted = I18n.t('not_graded', 'not graded')
        break
      case 'not_submitted':
        formatted = I18n.t('not_submitted', 'not submitted')
        break
      case 'resubmitted':
        formatted = I18n.t('graded_then_resubmitted', 'graded, then resubmitted (%{when})', {
          when: $.datetimeString(student.submission.submitted_at)
        })
        break
    }
    return {raw, formatted}
  },

  submissionState(student, grading_role) {
    const submission = student.submission
    if (
      submission &&
      submission.workflow_state != 'unsubmitted' &&
      (submission.submitted_at || !(typeof submission.grade === 'undefined'))
    ) {
      if (
        (grading_role == 'provisional_grader' || grading_role == 'moderator') &&
        !student.needs_provisional_grade &&
        submission.provisional_grade_id === null
      ) {
        // if we are a provisional grader and it doesn't need a grade (and we haven't given one already) then we shouldn't be able to grade it
        return 'not_gradeable'
      } else if (
        !(submission.final_provisional_grade && submission.final_provisional_grade.grade) &&
        !submission.excused &&
        (typeof submission.grade === 'undefined' ||
          submission.grade === null ||
          submission.workflow_state == 'pending_review')
      ) {
        return 'not_graded'
      } else if (submission.grade_matches_current_submission) {
        return 'graded'
      } else {
        return 'resubmitted'
      }
    } else {
      return 'not_submitted'
    }
  },
  plagiarismResubmitHandler: (event, resubmitUrl) => {
    event.preventDefault()

    $(event.target)
      .attr('disabled', true)
      .text(I18n.t('turnitin.resubmitting', 'Resubmitting...'))
    $.ajaxJSON(resubmitUrl, 'POST', {}, () => {
      speedGraderHelpers.reloadPage()
    })
  },

  plagiarismResubmitUrl(submission, anonymizableUserId) {
    return $.replaceTags($('#assignment_submission_resubmit_to_turnitin_url').attr('href'), {
      [anonymizableUserId]: submission[anonymizableUserId]
    })
  },

  plagiarismResubmitButton(hasOriginalityScore, buttonContainer) {
    if (hasOriginalityScore) {
      buttonContainer.hide()
    } else {
      buttonContainer.show()
    }
  },

  plagiarismErrorMessage(turnitinAsset) {
    return (
      turnitinAsset.error_message ||
      I18n.t(
        'There was an error submitting to the similarity detection service. Please try resubmitting the file before contacting support.'
      )
    )
  },

  reloadPage() {
    window.location.reload()
  },

  setupIsModerated,
  setupIsAnonymous,
  setupAnonymousGraders,
  setupAnonymizableId,
  setupAnonymizableUserId,
  setupAnonymizableStudentId,
  setupAnonymizableAuthorId
}

export default speedGraderHelpers
