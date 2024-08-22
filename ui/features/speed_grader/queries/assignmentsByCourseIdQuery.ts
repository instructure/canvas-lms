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

const QUERY = gql`
  query SpeedGrader_AssignmentsByCourseIdQuery($courseId: ID!) {
    course(id: $courseId) {
      _id
      id
      name
      assignmentGroupsConnection {
        nodes {
          _id
          id
          assignmentsConnection {
            nodes {
              _id
              id
              name
              pointsPossible
            }
          }
        }
      }
    }
  }
`

function transform({course}: any) {
  return {
    id: course.id,
    name: course.name,
    assignmentGroups: course.assignmentGroupsConnection.nodes.map((group: any) => ({
      _id: group._id,
      id: group.id,
      assignments: group.assignmentsConnection.nodes.map((assignment: any) => ({
        _id: assignment._id,
        id: assignment.id,
        name: assignment.name,
        pointsPossible: assignment.pointsPossible,
      })),
    })),
  }
}

export const ZParams = z.object({
  courseId: z.string().min(1),
})

type GetSectionsParams = z.infer<typeof ZParams>

export async function getAssignmentsByCourseId<T extends GetSectionsParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZParams.parse(queryKey[1])
  const {courseId} = queryKey[1]

  const result = await executeQuery<any>(QUERY, {
    courseId,
  })

  return transform(result)
}
