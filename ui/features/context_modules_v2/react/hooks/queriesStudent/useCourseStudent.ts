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
import {CourseStudentResponse, CourseStudentGraphQLResult} from '../../utils/types.d'

const COURSE_STUDENT_QUERY = gql`
  query GetCourseStudentQuery($courseId: ID!) {
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        name
        submissionStatistics {
          missingSubmissionsCount
          submissionsDueThisWeekCount
        }
      }
    }
  }
`

async function getCourseStudent(courseId: string): Promise<CourseStudentResponse> {
  const result = await executeQuery<CourseStudentGraphQLResult>(COURSE_STUDENT_QUERY, {
    courseId,
  })

  if (result.errors) {
    throw new Error(result.errors.map(err => err.message).join(', '))
  }

  return {
    name: result.legacyNode?.name,
    submissionStatistics: result.legacyNode?.submissionStatistics,
  }
}

export function useCourseStudent(courseId: string) {
  return useQuery<CourseStudentResponse, Error>({
    queryKey: ['courseStudent', courseId],
    queryFn: () => getCourseStudent(courseId),
  })
}
