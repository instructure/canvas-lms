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

import {chunk} from 'es-toolkit/compat'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {RequestDispatch} from '@canvas/network'
import type {Student, UserSubmissionGroup} from '../../../../../api.d'
import GRADEBOOK_GRAPHQL_CONFIG from './graphql/config'

/**
 * Calculates the optimal number of students per submission request to maximize
 * parallel request efficiency. This function ensures we use the maximum allowed
 * parallel threads by distributing students across requests rather than making
 * fewer requests with more students each. For example, with many students, it's
 * faster to make more parallel requests with fewer students per request than
 * fewer requests with many students each.
 *
 * Returns `GRADEBOOK_GRAPHQL_CONFIG.minNumberOfStudentsPerSubmissionRequest`
 * students per request to ensure efficient batching.
 */
export const smartStudentsPerSubmissionRequest = (totalCount: number) => {
  return Math.min(
    Math.max(
      GRADEBOOK_GRAPHQL_CONFIG.minNumberOfStudentsPerSubmissionRequest,
      Math.ceil(totalCount / GRADEBOOK_GRAPHQL_CONFIG.maxSubmissionRequestCount),
    ),
    GRADEBOOK_GRAPHQL_CONFIG.initialNumberOfStudentsPerSubmissionRequest,
  )
}

const I18n = createI18nScope('gradebook')

export function flashStudentLoadError(): void {
  showFlashAlert({
    message: I18n.t('There was a problem loading students.'),
    type: 'error',
    err: null,
  })
}

export function flashSubmissionLoadError(): void {
  showFlashAlert({
    message: I18n.t('There was a problem loading submissions.'),
    type: 'error',
    err: null,
  })
}

// @ts-expect-error
export function reportCatch(error) {
  console.warn(error)
}

export const submissionsParams = {
  include: ['sub_assignment_submissions'],
  exclude_response_fields: ['preview_url', 'external_tool_url', 'url'],
  grouped: 1,
  response_fields: [
    'assignment_id',
    'attachments',
    'attempt',
    'cached_due_date',
    'custom_grade_status_id',
    'entered_grade',
    'entered_score',
    'excused',
    'grade',
    'grade_matches_current_submission',
    'grading_period_id',
    'id',
    'late',
    'late_policy_status',
    'missing',
    'points_deducted',
    'posted_at',
    'proxy_submitter',
    'proxy_submitter_id',
    'redo_request',
    'score',
    'seconds_late',
    'sticker',
    'submission_type',
    'submitted_at',
    'user_id',
    'workflow_state',
  ],
}

export function getStudentsChunk(
  courseId: string,
  studentIds: string[],
  dispatch: RequestDispatch,
  correlationId: string,
) {
  const params = {
    enrollment_state: ['active', 'completed', 'inactive', 'invited'],
    enrollment_type: ['student', 'student_view'],
    include: ['avatar_url', 'enrollments', 'group_ids', 'last_name', 'first_name'],
    per_page: studentIds.length,
    user_ids: studentIds,
  }
  return dispatch.getJSON<Student[]>(`/api/v1/courses/${courseId}/users`, params, {
    'Correlation-Id': correlationId, // Enables request correlation for performance monitoring and analysis
  })
}

export function getSubmissionsForStudents(
  submissionsPerPage: number,
  courseId: string,
  studentIds: string[],
  // @ts-expect-error
  allEnqueued,
  dispatch: RequestDispatch,
  correlationId: string,
) {
  return new Promise<UserSubmissionGroup[]>((resolve, reject) => {
    const url = `/api/v1/courses/${courseId}/students/submissions`
    const params = {
      ...submissionsParams,
      student_ids: studentIds,
      per_page: submissionsPerPage,
    }

    dispatch
      .getDepaginated<UserSubmissionGroup[]>(url, params, undefined, allEnqueued, {
        'Correlation-Id': correlationId, // Enables request correlation for performance monitoring and analysis
      })
      .then(resolve)
      .catch(() => {
        flashSubmissionLoadError()
        reject()
      })
  })
}

export function getContentForStudentIdChunk(
  studentIds: string[],
  courseId: string,
  dispatch: RequestDispatch,
  submissionsChunkSize: number,
  submissionsPerPage: number,
  gotChunkOfStudents: (students: Student[]) => void,
  gotSubmissionsChunk: (student_submission_groups: UserSubmissionGroup[]) => void,
  correlationId: string,
) {
  // @ts-expect-error
  let resolveEnqueued
  const allEnqueued = new Promise(resolve => {
    resolveEnqueued = resolve
  })

  const studentRequest = getStudentsChunk(courseId, studentIds, dispatch, correlationId).then(
    gotChunkOfStudents,
  )

  const submissionRequestChunks = chunk(studentIds, submissionsChunkSize)
  const submissionRequests: Promise<void>[] = []

  submissionRequestChunks.forEach(submissionRequestChunkIds => {
    let submissions: UserSubmissionGroup[] = []

    const submissionRequest = getSubmissionsForStudents(
      submissionsPerPage,
      courseId,
      submissionRequestChunkIds,
      // @ts-expect-error
      resolveEnqueued,
      dispatch,
      correlationId,
    )
      .then(subs => (submissions = subs))
      // within the main Gradebook object, students must be received before
      // their related submissions can be received
      .then(() => studentRequest)
      .then(() => {
        // if the student request fails, this callback will not be called
        // the failure will be caught and otherwise ignored
        return gotSubmissionsChunk(submissions)
      })
      .catch(reportCatch)

    submissionRequests.push(submissionRequest)
  })

  return {
    allEnqueued,
    studentRequest: studentRequest.catch(flashStudentLoadError), // ignore failed student requests
    submissionRequests,
  }
}
