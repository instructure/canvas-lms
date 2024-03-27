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

import {z} from 'zod'
import getCookie from '@instructure/get-cookie'

function transform(result: any) {
  if (result.errors?.length > 0) {
    throw new Error(result.errors[0].message)
  }

  const {submission} = result[0]
  return {
    submission: {
      _id: submission.id,
      grade: submission.grade,
      score: submission.score,
    },
  }
}

export const ZUpdateSubmissionGradeParams = z.object({
  assignmentId: z.string(),
  userId: z.string(),
  gradedAnonymously: z.boolean(),
  grade: z.string(),
})

type UpdateSubmissionGradeParams = z.infer<typeof ZUpdateSubmissionGradeParams>

export async function updateSubmissionGrade({
  assignmentId,
  userId,
  gradedAnonymously,
  grade,
}: UpdateSubmissionGradeParams): Promise<any> {
  const data = {
    submission: {
      assignment_id: assignmentId,
      user_id: userId,
      graded_anonymously: gradedAnonymously,
      originator: 'speed_grader',
      grade,
    },
  }

  const response = await fetch('/courses/1/gradebook/update_submission', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCookie('_csrf_token'),
      Accept: 'application/json',
    },
    body: JSON.stringify(data),
  })

  const json = await response.json()
  return transform(json)
}
