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

import {filter, find, map, some} from 'es-toolkit/compat'
import axios from '@canvas/axios'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Student} from '../../api.d'

const I18n = createI18nScope('gradebooksharedMessageStudentsWhoHelper')

type SubmissionData = {
  excused?: boolean
  latePolicyStatus?: string
  submittedAt?: string
  submitted_at?: string
  score?: number | string | null
}

type AssignmentData = {
  name: string
  points_possible: number
  courseId?: string
  course_id?: string
  submissionTypes?: string[]
  submission_types?: string[]
}

type StudentData = {
  id: string
  score?: number | string | null
}

type OptionCriteria = {
  text: string
  cutoff?: boolean
  subjectFn: (assignment: AssignmentData, cutoff?: number) => string
  criteriaFn: (student: StudentData, cutoff?: number) => boolean
}

type WrappedStudent = {
  user_data: StudentData
}

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

export function hasSubmitted(submission: SubmissionData): boolean {
  if (submission.excused) {
    return true
  } else if (submission.latePolicyStatus) {
    return submission.latePolicyStatus !== 'missing'
  }

  return !!(submission.submittedAt || submission.submitted_at)
}

export function hasGraded(submission: SubmissionData): boolean {
  if (submission.excused) {
    return true
  }

  return MessageStudentsWhoHelper.exists(submission.score)
}

export function hasSubmission(assignment: AssignmentData): boolean {
  const submissionTypes = getSubmissionTypes(assignment)
  if (submissionTypes.length === 0) return false

  return some(
    submissionTypes,
    submissionType => submissionType !== 'none' && submissionType !== 'on_paper',
  )
}

function getSubmissionTypes(assignment: AssignmentData): string[] {
  return assignment.submissionTypes || assignment.submission_types || []
}

function getCourseId(assignment: AssignmentData): string | undefined {
  return assignment.courseId || assignment.course_id
}

const MessageStudentsWhoHelper = {
  settings(assignment: AssignmentData, students: Student[]) {
    const settings: {
      title: string
      points_possible: number
      students: Student[]
      context_code: string
      callback: (
        selected: string,
        cutoff: number | undefined,
        students: WrappedStudent[],
      ) => string[]
      subjectCallback: (selected: string, cutoff: number | undefined) => string
      options: OptionCriteria[]
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
    attachmentIds: null | string[] = null,
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

  options(assignment: AssignmentData): OptionCriteria[] {
    const options = this.allOptions()
    const noSubmissions = !this.hasSubmission(assignment)
    if (noSubmissions) options.splice(0, 1)
    return options
  },

  allOptions(): OptionCriteria[] {
    return [
      {
        text: I18n.t("Haven't submitted yet"),
        subjectFn: (assignment: AssignmentData) =>
          I18n.t('No submission for %{assignment}', {assignment: assignment.name}),
        criteriaFn: (student: StudentData) => !hasSubmitted(student),
      },
      {
        text: I18n.t("Haven't been graded"),
        subjectFn: (assignment: AssignmentData) =>
          I18n.t('No grade for %{assignment}', {assignment: assignment.name}),
        criteriaFn: (student: StudentData) => !hasGraded(student),
      },
      {
        text: I18n.t('Scored less than'),
        cutoff: true,
        subjectFn: (assignment: AssignmentData, cutoff?: number) =>
          I18n.t('Scored less than %{cutoff} on %{assignment}', {
            assignment: assignment.name,
            cutoff: I18n.n(cutoff || 0),
          }),
        criteriaFn: (student: StudentData, cutoff?: number) =>
          this.scoreWithCutoff(student, cutoff) && Number(student.score) < (cutoff || 0),
      },
      {
        text: I18n.t('Scored more than'),
        cutoff: true,
        subjectFn: (assignment: AssignmentData, cutoff?: number) =>
          I18n.t('Scored more than %{cutoff} on %{assignment}', {
            assignment: assignment.name,
            cutoff: I18n.n(cutoff || 0),
          }),
        criteriaFn: (student: StudentData, cutoff?: number) =>
          this.scoreWithCutoff(student, cutoff) && Number(student.score) > (cutoff || 0),
      },
    ]
  },

  // implement this so it can be stubbed in tests
  hasSubmission(assignment: AssignmentData): boolean {
    return hasSubmission(assignment)
  },

  exists(value: unknown): boolean {
    return value != null
  },

  scoreWithCutoff(student: StudentData, cutoff: number | undefined): boolean {
    return this.exists(student.score) && student.score !== '' && this.exists(cutoff)
  },

  callbackFn(selected: string, cutoff: number | undefined, students: WrappedStudent[]): string[] {
    const option = this.findOptionByText(selected)
    if (!option) return []
    const criteriaFn = option.criteriaFn
    const studentsMatchingCriteria = filter(students, (student: WrappedStudent) =>
      criteriaFn(student.user_data, cutoff),
    )
    return map(studentsMatchingCriteria, (student: WrappedStudent) => student.user_data.id)
  },

  findOptionByText(text: string): OptionCriteria | undefined {
    return find(this.allOptions(), option => option.text === text)
  },

  generateSubjectCallbackFn(assignment: AssignmentData) {
    return (selected: string, cutoff: number | undefined): string => {
      const cutoffValue = cutoff || 0
      const option = this.findOptionByText(selected)
      if (!option) return ''
      const subjectFn = option.subjectFn
      return subjectFn(assignment, cutoffValue)
    }
  },
}
export default MessageStudentsWhoHelper
