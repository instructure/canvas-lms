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
import I18n from 'i18n!gradebook'

import {showFlashAlert} from '../../../shared/FlashAlert'

const submissionsParams = {
  exclude_response_fields: ['preview_url'],
  grouped: 1,
  response_fields: [
    'assignment_id',
    'attachments',
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
    'score',
    'seconds_late',
    'submission_type',
    'submitted_at',
    'url',
    'user_id',
    'workflow_state'
  ]
}

function flashStudentLoadError() {
  showFlashAlert({
    message: I18n.t('There was a problem loading students.'),
    type: 'error'
  })
}

function flashSubmissionLoadError() {
  showFlashAlert({
    message: I18n.t('There was a problem loading submissions.'),
    type: 'error'
  })
}

function ignoreFailure() {}

function getStudentsChunk(courseId, studentIds, options) {
  const url = `/api/v1/courses/${courseId}/users`
  const params = {
    enrollment_state: ['active', 'completed', 'inactive', 'invited'],
    enrollment_type: ['student', 'student_view'],
    include: ['avatar_url', 'enrollments', 'group_ids'],
    per_page: studentIds.length,
    user_ids: studentIds
  }

  return options.dispatch.getJSON(url, params)
}

function getSubmissionsForStudents(options, studentIds, allEnqueued, dispatch) {
  return new Promise((resolve, reject) => {
    const {courseId, submissionsPerPage} = options
    const url = `/api/v1/courses/${courseId}/students/submissions`
    const params = {...submissionsParams, student_ids: studentIds, per_page: submissionsPerPage}

    dispatch
      .getDepaginated(url, params, undefined, allEnqueued)
      .then(resolve)
      .catch(() => {
        flashSubmissionLoadError()
        reject()
      })
  })
}

function getContentForStudentIdChunk(studentIds, options) {
  const {dispatch, gradebook, submissionsChunkSize} = options

  let resolveEnqueued
  const allEnqueued = new Promise(resolve => {
    resolveEnqueued = resolve
  })

  const studentRequest = getStudentsChunk(options.courseId, studentIds, options).then(
    gradebook.gotChunkOfStudents
  )

  const submissionRequestChunks = chunk(studentIds, submissionsChunkSize)
  const submissionRequests = []

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
    submissionRequests
  }
}

export default class StudentContentDataLoader {
  constructor({dispatch, gradebook, performanceControls}) {
    this._dispatch = dispatch
    this._gradebook = gradebook
    this._performanceControls = performanceControls
  }

  load(studentIds) {
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
      submissionsPerPage: this._performanceControls.submissionsPerPage
    }

    const studentRequests = []
    const submissionRequests = []
    const studentIdChunks = chunk(studentIds, this._performanceControls.studentsChunkSize)

    // wait for all chunk requests to have been enqueued
    return new Promise(resolve => {
      const getNextChunk = () => {
        if (studentIdChunks.length) {
          const nextChunkIds = studentIdChunks.shift()
          const chunkRequestDatum = getContentForStudentIdChunk(nextChunkIds, options)

          // when the current chunk requests are all enqueued
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
        const {courseSettings, finalGradeOverrides} = gradebook
        let finalGradeOverridesRequest
        if (courseSettings.allowFinalGradeOverride) {
          finalGradeOverridesRequest = finalGradeOverrides.loadFinalGradeOverrides()
        }

        // wait for all student, submission, and final grade override requests to return
        return Promise.all([...studentRequests, ...submissionRequests, finalGradeOverridesRequest])
      })
      .then(() => {
        gradebook.updateStudentsLoaded(true)
        gradebook.updateSubmissionsLoaded(true)
      })
  }
}
