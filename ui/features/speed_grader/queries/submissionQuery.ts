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

export const ZGetSubmissionParams = z.object({
  courseId: z.string(),
  assignmentId: z.string(),
  userId: z.string(),
})

type GetSubmissionParams = z.infer<typeof ZGetSubmissionParams>

export function getSubmission<T extends GetSubmissionParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetSubmissionParams.parse(queryKey[1])
  const {courseId, assignmentId, userId} = queryKey[1]

  const include = ['submission_comments', 'submission_history', 'user']
  const includeParams = include.map(i => `include[]=${i}`).join('&')
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${userId}?${includeParams}`

  return fetch(url)
    .then(res => res.json())
    .then(data => {
      // later: transform
      return data
    })
}
