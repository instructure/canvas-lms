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

export interface CourseStudent {
  _id: string
  name: string
}

export interface CourseStudentsData {
  course: {
    usersConnection: {
      nodes: CourseStudent[]
    }
  }
}

export interface CourseStudentsVariables {
  courseId: string
  filter?: {
    searchTerm?: string
    excludeTestStudents: boolean
  }
}

export interface AssignedStudentsData {
  assignment: {
    assignedStudents: {
      nodes: CourseStudent[]
    }
  }
}

export interface AssignedStudentsVariables {
  assignmentId: string
  filter?: {
    searchTerm?: string
  }
}

export const ASSIGNED_STUDENTS_QUERY = gql`
  query GetAssignedStudents($assignmentId: ID!, $filter: AssignedStudentsFilter) {
    assignment(id: $assignmentId) {
      assignedStudents(filter: $filter) {
        nodes {
          _id
          name
        }
      }
    }
  }
`

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
