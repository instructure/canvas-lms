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
    enrollmentsConnection: {
      nodes: {
        user: {
          name: string
          _id: string
          sortableName: string
        }
      }[]
    }
  }
}

const QUERY = gql`
  query SpeedGrader_EnrollmentsByCourseQuery($courseId: ID!) {
    course(id: $courseId) {
      enrollmentsConnection(filter: {types: StudentEnrollment}) {
        nodes {
          user {
            name
            _id
            sortableName
          }
        }
      }
    }
  }
`

export const ZParams = z.object({
  courseId: z.string().min(1),
})

type Params = z.infer<typeof ZParams>

export function getCourseEnrollments<T extends Params>({queryKey}: {queryKey: [string, T]}) {
  ZParams.parse(queryKey[1])
  const {courseId} = queryKey[1]

  return executeQuery<Result>(QUERY, {
    courseId,
  })
}
