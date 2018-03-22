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

import $ from 'jquery'
import _ from 'lodash'
import 'jquery.ajaxJSON'
import I18n from 'i18n!gradebook'
import cheaterDepaginate from '../../../shared/CheatDepaginator'
import {showFlashAlert} from '../../../shared/FlashAlert'

const submissionsParams = {
  exclude_response_fields: ['preview_url'],
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

function getStudentsChunk(studentIds, options) {
  const params = {
    ...options.studentsParams,
    per_page: options.studentsChunkSize,
    user_ids: studentIds
  }
  return new Promise((resolve, reject) => {
    $.ajaxJSON(options.studentsUrl, 'GET', params, resolve, reject)
  })
}

function getSubmissionsForStudents(studentIds, options, allEnqueued) {
  return new Promise((resolve, reject) => {
    const params = {student_ids: studentIds, ...submissionsParams}
    cheaterDepaginate(options.submissionsUrl, params, null, allEnqueued)
      .then(resolve)
      .fail(() => {
        flashSubmissionLoadError()
        reject()
      })
  })
}

function getContentForStudentIdChunk(studentIds, options) {
  let resolveEnqueued
  const allEnqueued = new Promise(resolve => {
    resolveEnqueued = resolve
  })

  const studentRequest = getStudentsChunk(studentIds, options).then(options.onStudentsChunkLoaded)

  const submissionRequestChunks = _.chunk(studentIds, options.submissionsChunkSize)
  const submissionRequests = []

  submissionRequestChunks.forEach(submissionRequestChunkIds => {
    const submissionRequest = getSubmissionsForStudents(
      submissionRequestChunkIds,
      options,
      resolveEnqueued
    )
      .then(async submissions => {
        // within the main Gradebook object, students must be received before
        // their related submissions can be received
        await studentRequest
        // if the student request fails, this callback will not be called
        // the failure will be caught and otherwise ignored
        options.onSubmissionsChunkLoaded(submissions)
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
  constructor(options) {
    this.options = options
  }

  async load(studentIds) {
    const loadedStudentIds = this.options.loadedStudentIds || []
    const studentIdsToLoad = _.difference(studentIds, loadedStudentIds)

    if (studentIdsToLoad.length === 0) {
      return
    }

    const studentRequests = []
    const submissionRequests = []
    const studentIdChunks = _.chunk(studentIdsToLoad, this.options.studentsChunkSize)

    // wait for all chunk requests to have been enqueued
    await new Promise(resolve => {
      const getNextChunk = () => {
        if (studentIdChunks.length) {
          const nextChunkIds = studentIdChunks.shift()
          const chunkRequestDatum = getContentForStudentIdChunk(nextChunkIds, this.options)

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

    // wait for all student and submission requests to return
    await Promise.all([...studentRequests, ...submissionRequests])
  }
}
