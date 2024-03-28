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

const SECTIONS_BY_ASSIGNMENT_QUERY = gql`
  query SectionsByAssignmentQuery($assignmentId: ID!, $courseId: ID!) {
    course(id: $courseId) {
      sectionsConnection(filter: {assignmentId: $assignmentId}) {
        nodes {
          id
          _id
          name
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

function transform(result: any) {
  if (result.course?.sectionsConnection?.nodes) {
    const sections = result.course.sectionsConnection.nodes
    return sections.map((section: any) => {
      return {
        ...section,
        students: section.students.nodes.map((student: any) => {
          return student._id
        }),
      }
    })
  }
  return null
}

export const ZGetSectionsParams = z.object({
  assignmentId: z.string(),
  courseId: z.string(),
})

type GetSectionsParams = z.infer<typeof ZGetSectionsParams>

export async function getSectionsByAssignment<T extends GetSectionsParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetSectionsParams.parse(queryKey[1])
  const {assignmentId, courseId} = queryKey[1]

  const result = await executeQuery<any>(SECTIONS_BY_ASSIGNMENT_QUERY, {
    assignmentId,
    courseId,
  })

  return transform(result)
}
