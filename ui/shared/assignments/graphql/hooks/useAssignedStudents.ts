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
import {executeQuery} from '@canvas/graphql'
import {AssignedStudentsData, CourseStudent} from '../teacher/AssignmentTeacherTypes'
import {ASSIGNED_STUDENTS_QUERY} from '../teacher/Queries'

async function getAssignedStudents(
  assignmentId: string,
  searchTerm?: string,
): Promise<CourseStudent[]> {
  const result = await executeQuery<AssignedStudentsData>(ASSIGNED_STUDENTS_QUERY, {
    assignmentId,
    filter: {
      searchTerm,
    },
  })

  return result.assignment?.assignedStudents?.nodes || []
}

export const useAssignedStudents = (assignmentId: string, searchTerm = '') => {
  const trimmedSearchTerm = searchTerm.trim()
  const finalSearchTerm = trimmedSearchTerm || undefined

  const assignedStudentsQuery = useQuery<CourseStudent[], Error>({
    queryKey: ['assignedStudents', assignmentId, finalSearchTerm],
    queryFn: () => getAssignedStudents(assignmentId, finalSearchTerm),
    enabled: !!assignmentId,
    networkMode: 'always',
  })

  if (assignmentId) {
    return {
      students: assignedStudentsQuery.data || [],
      loading: assignedStudentsQuery.isLoading,
      error: assignedStudentsQuery.error,
    }
  }

  return {
    students: [],
    loading: false,
    error: null,
  }
}
