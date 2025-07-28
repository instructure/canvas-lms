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
import {executeQuery} from '@canvas/graphql'
import {gql} from '@apollo/client'

const QUERY = gql`
  query CourseAndModulePicker_AssignmentsByCourseIdQuery($courseId: ID!) {
    course(id: $courseId) {
      _id
      id
      name
      assignmentsConnection {
        nodes {
          _id
          id
          name
          rubricAssociation {
            _id
          }
        }
      }
    }
  }
`

export interface AssignmentItem {
  _id: string
  id: string
  name: string
  rubric_id?: string | null
}

function transform({course}: any): AssignmentItem[] {
  return course.assignmentsConnection.nodes.map(
    (assignment: any): AssignmentItem => ({
      _id: assignment._id,
      id: assignment.id,
      name: assignment.name,
      rubric_id: assignment.rubricAssociation?._id,
    }),
  )
}

export const ZParams = z.object({
  courseId: z.string().min(1),
})

export async function getAssignmentsByCourseId(courseId: string): Promise<any> {
  ZParams.parse({courseId})

  const result = await executeQuery<any>(QUERY, {
    courseId,
  })

  return transform(result)
}
