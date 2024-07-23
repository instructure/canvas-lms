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
import {executeQuery} from '@canvas/query/graphql'
import gql from 'graphql-tag'

const SUBMISSIONS_BY_STUDENT_IDS_QUERY = gql`
  query SubmissionsByStudentsQuery {
    course(id: $courseId) {
      id
      submissionsConnection(studentIds: $studentIds) {
        nodes {
          id
          submittedAt
          state
          score
          late
        }
      }
    }
  }
`

function transform(result: any) {
  if (result.course?.submissionsConnection?.nodes) {
    return result.course.submissionsConnection.nodes
  }
  return null
}

export const ZGetSubmissionsByStudentIdsParams = z.object({
  studentIds: z.array(z.string()),
})

type GetSubmissionsByStudentIdsParams = z.infer<typeof ZGetSubmissionsByStudentIdsParams>

export async function getSubmissionsByStudentIds<T extends GetSubmissionsByStudentIdsParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetSubmissionsByStudentIdsParams.parse(queryKey[1])
  const {studentIds} = queryKey[1]

  const result = await executeQuery<any>(SUBMISSIONS_BY_STUDENT_IDS_QUERY, {
    studentIds,
  })

  return transform(result)
}
