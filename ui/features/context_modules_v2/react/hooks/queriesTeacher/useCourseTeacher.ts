/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {CourseTeacherResponse, CourseTeacherGraphQLResult} from '../../utils/types'

const COURSE_TEACHER_QUERY = gql`
  query GetCourseTeacherQuery($courseId: ID!) {
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        name
        settings {
          showStudentOnlyModuleId
          showTeacherOnlyModuleId
        }
      }
    }
  }
`

async function getCourseTeacher(courseId: string): Promise<CourseTeacherResponse> {
  const result = await executeQuery<CourseTeacherGraphQLResult>(COURSE_TEACHER_QUERY, {
    courseId,
  })

  if (result.errors) {
    throw new Error(result.errors.map(err => err.message).join(', '))
  }

  return {
    name: result.legacyNode?.name,
    settings: result.legacyNode?.settings,
  }
}

export function useCourseTeacher(courseId: string) {
  return useQuery<CourseTeacherResponse, Error>({
    queryKey: ['courseTeacher', courseId],
    queryFn: () => getCourseTeacher(courseId),
  })
}
