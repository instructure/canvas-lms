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

type Result = {
  course: {
    submissionsConnection: {
      nodes: {
        assignmentId: string
        id: string
        late: boolean
        score: number | null
        state: string
        submittedAt: string | null
        userId: string
      }[]
    }
  }
}

const QUERY = gql`
  query SpeedGrader_SubmissionsByStudentsQuery($courseId: ID!, $studentIds: [ID!]!) {
    course(id: $courseId) {
      submissionsConnection(studentIds: $studentIds) {
        nodes {
          assignmentId
          id
          late
          score
          state
          submittedAt
          userId
        }
      }
    }
  }
`

export const ZGetSubmissionsByStudentIdsParams = z.object({
  courseId: z.string().min(1),
  studentIds: z.array(z.string().min(1)),
})

type GetSubmissionsByStudentIdsParams = z.infer<typeof ZGetSubmissionsByStudentIdsParams>

export function getSubmissionsByStudents<T extends GetSubmissionsByStudentIdsParams>({
  queryKey,
}: {
  queryKey: [string, T]
}) {
  ZGetSubmissionsByStudentIdsParams.parse(queryKey[1])
  const {courseId, studentIds} = queryKey[1]

  return executeQuery<Result>(QUERY, {
    courseId,
    studentIds,
  })
}
