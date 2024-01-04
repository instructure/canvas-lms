/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import {underscoreProperties} from '@canvas/convert-case'

export function determineSubmissionSelection(submission) {
  if (submission.custom_grade_status_id) {
    return submission.custom_grade_status_id
  } else if (submission.excused) {
    return 'excused'
  } else if (submission.missing) {
    return 'missing'
  } else if (submission.late) {
    return 'late'
  } else if (submission.late_policy_status === 'extended') {
    return 'extended'
  } else {
    return 'none'
  }
}

export function makeSubmissionUpdateRequest(submission, isAnonymous, courseId, updateData) {
  const data = {}
  const submissionData = {
    assignmentId: submission.assignment_id,
    ...updateData,
  }

  let url
  if (isAnonymous) {
    url = `/api/v1/courses/${courseId}/assignments/${submission.assignment_id}/anonymous_submissions/${submission.anonymous_id}`
  } else {
    submissionData.userId = submission.user_id
    url = `/api/v1/courses/${courseId}/assignments/${submission.assignment_id}/submissions/${submission.user_id}`
  }

  data.submission = underscoreProperties(submissionData)
  return axios.put(url, data)
}
