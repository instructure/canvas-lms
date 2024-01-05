// @ts-nocheck
/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {filter, find, map, some} from 'lodash'
import axios from '@canvas/axios'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Student} from '../../api.d'

const I18n = useI18nScope('gradebooksharedMessageStudentsWhoHelper')

type MessageStudentParams = {
  recipients: string[]
  subject: string
  body: string
  context_code: string
  mode: string
  group_conversation: boolean
  bulk_message: boolean
  media_comment_id?: string
  media_comment_type?: string
  attachment_ids?: string[]
}

export function hasSubmitted(submission) {
  if (submission.excused) {
    return true
  } else if (submission.latePolicyStatus) {
    return submission.latePolicyStatus !== 'missing'
  }

  return !!(submission.submittedAt || submission.submitted_at)
}

export function hasGraded(submission) {
  if (submission.excused) {
    return true
  }

  return MessageStudentsWhoHelper.exists(submission.score)
}

export function hasSubmission(assignment) {
  const submissionTypes = getSubmissionTypes(assignment)
  if (submissionTypes.length === 0) return false

  return some(
    submissionTypes,
    submissionType => submissionType !== 'none' && submissionType !== 'on_paper'
  )
}

function getSubmissionTypes(assignment) {
  return assignment.submissionTypes || assignment.submission_types
}

function getCourseId(assignment) {
  return assignment.courseId || assignment.course_id
}

const MessageStudentsWhoHelper = {
  settings(assignment, students) {
    const settings: {
      title: string
      points_possible: number
      students: Student[]
      context_code: string
      callback: (selected: any, cutoff: any, students: any) => any
      subjectCallback: (selected: any, cutoff: any) => any
      options: any[]
      onClose?: () => void
    } = {
      options: this.options(assignment),
      title: assignment.name,
      points_possible: assignment.points_possible,
      students,
      context_code: `course_${getCourseId(assignment)}`,
      callback: this.callbackFn.bind(this),
      subjectCallback: this.generateSubjectCallbackFn(assignment),
    }

    return settings
  },

  sendMessageStudentsWho(
    recipientsIds: string[],
    subject: string,
    body: string,
    contextCode: string,
    mediaFile?: {id: string; type: string},
    attachmentIds: null | string[] = null
  ) {
    const params: MessageStudentParams = {
      recipients: recipientsIds,
      subject,
      body,
      context_code: contextCode,
      mode: 'async',
      group_conversation: true,
      bulk_message: true,
      media_comment_id: undefined,
      media_comment_type: undefined,
    }

    if (mediaFile) {
      params.media_comment_id = mediaFile.id
      params.media_comment_type = mediaFile.type
    }

    if (attachmentIds) {
      params.attachment_ids = attachmentIds
    }

    return axios.post('/api/v1/conversations', params)
  },

  options(assignment) {
    const options = this.allOptions()
    const noSubmissions = !this.hasSubmission(assignment)
    if (noSubmissions) options.splice(0, 1)
    return options
  },

  allOptions() {
    return [
      {
        text: I18n.t("Haven't submitted yet"),
        subjectFn: assignment =>
          I18n.t('No submission for %{assignment}', {assignment: assignment.name}),
        criteriaFn: student => !hasSubmitted(student),
      },
      {
        text: I18n.t("Haven't been graded"),
        subjectFn: assignment =>
          I18n.t('No grade for %{assignment}', {assignment: assignment.name}),
        criteriaFn: student => !hasGraded(student),
      },
      {
        text: I18n.t('Scored less than'),
        cutoff: true,
        subjectFn: (assignment, cutoff: number) =>
          I18n.t('Scored less than %{cutoff} on %{assignment}', {
            assignment: assignment.name,
            cutoff: I18n.n(cutoff),
          }),
        criteriaFn: (student, cutoff) =>
          this.scoreWithCutoff(student, cutoff) && student.score < cutoff,
      },
      {
        text: I18n.t('Scored more than'),
        cutoff: true,
        subjectFn: (assignment, cutoff: number) =>
          I18n.t('Scored more than %{cutoff} on %{assignment}', {
            assignment: assignment.name,
            cutoff: I18n.n(cutoff),
          }),
        criteriaFn: (student, cutoff) =>
          this.scoreWithCutoff(student, cutoff) && student.score > cutoff,
      },
    ]
  },

  // implement this so it can be stubbed in tests
  hasSubmission(assignment) {
    return hasSubmission(assignment)
  },

  exists(value) {
    return value != null
  },

  scoreWithCutoff(student, cutoff) {
    return this.exists(student.score) && student.score !== '' && this.exists(cutoff)
  },

  callbackFn(selected, cutoff, students) {
    const criteriaFn = this.findOptionByText(selected).criteriaFn
    const studentsMatchingCriteria = filter(students, student =>
      criteriaFn(student.user_data, cutoff)
    )
    return map(studentsMatchingCriteria, student => student.user_data.id)
  },

  findOptionByText(text) {
    return find(this.allOptions(), option => option.text === text)
  },

  generateSubjectCallbackFn(assignment) {
    return (selected, cutoff) => {
      const cutoffString = cutoff || ''
      const subjectFn = this.findOptionByText(selected).subjectFn
      return subjectFn(assignment, cutoffString)
    }
  },
}
export default MessageStudentsWhoHelper
