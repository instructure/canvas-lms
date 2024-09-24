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
    sectionsConnection: {
      nodes: {
        id: string
        _id: string
        name: string
        gradesPosted: boolean
        students: {
          nodes: {
            _id: string
          }[]
        }
      }[]
    }
  }
}

const QUERY = gql`
  query SpeedGrader_SectionsByAssignmentQuery($assignmentId: ID!, $courseId: ID!) {
    course(id: $courseId) {
      sectionsConnection(filter: {assignmentId: $assignmentId}) {
        nodes {
          id
          _id
          name
          gradesPosted(assignmentId: $assignmentId)
          students {
            nodes {
              _id
            }
          }
        }
      }
    }
  }
`

export const ZGetSectionsParams = z.object({
  assignmentId: z.string().min(1),
  courseId: z.string().min(1),
})

type GetSectionsParams = z.infer<typeof ZGetSectionsParams>

export function getAssignmentSections<T extends GetSectionsParams>({
  queryKey,
}: {
  queryKey: [string, T]
}) {
  ZGetSectionsParams.parse(queryKey[1])
  const {assignmentId, courseId} = queryKey[1]

  return executeQuery<Result>(QUERY, {
    assignmentId,
    courseId,
  })
}
