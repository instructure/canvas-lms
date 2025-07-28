/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import doFetchApi from '@canvas/do-fetch-api-effect'

type Props = {
  secondsLate: number
  courseId: string
  assignmentId: string
  userId: string
  latePolicyStatus?: string
}
export const updateSubmissionSecondsLate = ({
  secondsLate,
  courseId,
  assignmentId,
  userId,
  latePolicyStatus,
}: Props) => {
  const data = {
    submission: {
      assignment_id: assignmentId,
      late_policy_status: latePolicyStatus || 'late',
      seconds_late_override: secondsLate,
      user_id: userId,
    },
  }
  // TODO: anonymous grading url here, see makeSubmissionUpdateRequest in SpeedGraderStatusMenuHelpers.js
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${userId}`
  const method = 'PUT'
  return doFetchApi({
    path: url,
    method,
    body: data,
  })
}
