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
import {omit} from 'lodash'

const QUERY = gql`
  query GradebookQuery($courseId: ID!) {
    course(id: $courseId) {
      enrollmentsConnection(
        filter: {
          states: [active, invited, completed]
          types: [StudentEnrollment, StudentViewEnrollment]
        }
      ) {
        nodes {
          user {
            id: _id
            name
            sortableName
          }
          courseSectionId
          state
        }
      }
      sectionsConnection {
        nodes {
          id: _id
          name
        }
      }
      assignmentGroupsConnection {
        nodes {
          id: _id
          name
          state
          position
          assignmentsConnection(filter: {gradingPeriodId: null}) {
            nodes {
              id: _id
              name
            }
          }
        }
      }
    }
  }
`

function transform(result: any) {
  return {
    assignmentGroups: result.course.assignmentGroupsConnection.nodes.map((group: any) =>
      omit(
        {
          ...group,
          assignments: group.assignmentsConnection.nodes,
        },
        ['assignmentsConnection']
      )
    ),
    enrollments: result.course.enrollmentsConnection.nodes,
    sections: result.course.sectionsConnection.nodes,
  }
}

export const ZParams = z.object({
  courseId: z.string(),
})

type Params = z.infer<typeof ZParams>

export async function getCourse<T extends Params>({
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
