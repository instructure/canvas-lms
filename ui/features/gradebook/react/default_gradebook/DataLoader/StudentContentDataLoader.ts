/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {chunk} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import type Gradebook from '../Gradebook'
import type {RequestDispatch} from '@canvas/network'
import type PerformanceControls from '../PerformanceControls'
import type {Student} from '../../../../../api.d'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('gradebook')

type Options = {
  dispatch: RequestDispatch
  gradebook: Gradebook
  submissionsChunkSize: number
  courseId: string
  submissionsPerPage: number
}

const submissionsParams = {
  exclude_response_fields: ['preview_url'],
  grouped: 1,
  response_fields: [
    'assignment_id',
    'attachments',
    'attempt',
    'cached_due_date',
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
    'redo_request',
    'score',
    'seconds_late',
    'submission_type',
    'submitted_at',
    'url',
    'user_id',
    'workflow_state',
  ],
}

function flashStudentLoadError(): void {
  showFlashAlert({
    message: I18n.t('There was a problem loading students.'),
    type: 'error',
    err: null,
  })
}

function flashSubmissionLoadError(): void {
  showFlashAlert({
    message: I18n.t('There was a problem loading submissions.'),
    type: 'error',
    err: null,
  })
}

function ignoreFailure() {}

function getStudentsChunk(courseId: string, studentIds: string[], options: Options) {
  const url = `/api/v1/courses/${courseId}/users`
  const params = {
    enrollment_state: ['active', 'completed', 'inactive', 'invited'],
    enrollment_type: ['student', 'student_view'],
    include: ['avatar_url', 'enrollments', 'group_ids', 'last_name', 'first_name'],
    per_page: studentIds.length,
    user_ids: studentIds,
  }

  return options.dispatch.getJSON<Student[]>(url, params)
}

function getSubmissionsForStudents(
  options: Options,
  studentIds: string[],
  allEnqueued,
  dispatch: RequestDispatch
) {
  return new Promise((resolve, reject) => {
    const {courseId, submissionsPerPage} = options
    const url = `/api/v1/courses/${courseId}/students/submissions`
    const params = {...submissionsParams, student_ids: studentIds, per_page: submissionsPerPage}

    dispatch
      .getDepaginated<Student[]>(url, params, undefined, allEnqueued)
      .then(resolve)
      .catch(() => {
        flashSubmissionLoadError()
        reject()
      })
  })
}

function getContentForStudentIdChunk(studentIds: string[], options: Options) {
  const {dispatch, gradebook, submissionsChunkSize} = options

  let resolveEnqueued
  const allEnqueued = new Promise(resolve => {
    resolveEnqueued = resolve
  })

  const studentRequest = getStudentsChunk(options.courseId, studentIds, options).then(
    gradebook.gotChunkOfStudents
  )

  const submissionRequestChunks = chunk(studentIds, submissionsChunkSize)
  const submissionRequests: Promise<void>[] = []

  submissionRequestChunks.forEach(submissionRequestChunkIds => {
    let submissions

    const submissionRequest = getSubmissionsForStudents(
      options,
      submissionRequestChunkIds,
      resolveEnqueued,
      dispatch
    )
      .then(subs => (submissions = subs))
      // within the main Gradebook object, students must be received before
      // their related submissions can be received
      .then(() => studentRequest)
      .then(() => {
        // if the student request fails, this callback will not be called
        // the failure will be caught and otherwise ignored
        gradebook.gotSubmissionsChunk(submissions)
      })
      .catch(ignoreFailure)

    submissionRequests.push(submissionRequest)
  })

  return {
    allEnqueued,
    studentRequest: studentRequest.catch(flashStudentLoadError), // ignore failed student requests
    submissionRequests,
  }
}

export default class StudentContentDataLoader {
  _dispatch: RequestDispatch

  _gradebook: Gradebook

  _performanceControls: PerformanceControls

  constructor({
    dispatch,
    gradebook,
    performanceControls,
  }: {
    dispatch: RequestDispatch
    gradebook: Gradebook
    performanceControls: PerformanceControls
  }) {
    this._dispatch = dispatch
    this._gradebook = gradebook
    this._performanceControls = performanceControls
  }

  load(studentIds: string[]) {
    const gradebook = this._gradebook

    if (studentIds.length === 0) {
      gradebook.updateStudentsLoaded(true)
      gradebook.updateSubmissionsLoaded(true)
      return
    }

    const options = {
      courseId: gradebook.course.id,
      dispatch: this._dispatch,
      gradebook,
      submissionsChunkSize: this._performanceControls.submissionsChunkSize,
      submissionsPerPage: this._performanceControls.submissionsPerPage,
    }

    const studentRequests: Promise<void>[] = []
    const submissionRequests: Promise<void>[] = []
    const studentIdChunks: string[][] = chunk(
      studentIds,
      this._performanceControls.studentsChunkSize
    )

    // wait for all chunk requests to have been enqueued
    return new Promise<void>(resolve => {
      const getNextChunk = () => {
        if (studentIdChunks.length) {
          const nextChunkIds = studentIdChunks.shift() as string[]
          const chunkRequestDatum = getContentForStudentIdChunk(nextChunkIds, options)

          // when the current chunk requests are all enqueued
          // eslint-disable-next-line promise/catch-or-return
          chunkRequestDatum.allEnqueued.then(() => {
            submissionRequests.push(...chunkRequestDatum.submissionRequests)
            studentRequests.push(chunkRequestDatum.studentRequest)
            getNextChunk()
          })
        } else {
          resolve()
        }
      }

      getNextChunk()
    })
      .then(() => {
        // wait for all student, submission requests to return
        return Promise.all([...studentRequests, ...submissionRequests])
      })
      .then(() => {
        gradebook.updateStudentsLoaded(true)
        gradebook.updateSubmissionsLoaded(true)
      })
  }
}
