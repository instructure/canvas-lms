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
import {COURSE_PEOPLE_QUERY} from '../../graphql/Queries'
import {executeQuery} from '@canvas/graphql'
import useCoursePeopleContext from './useCoursePeopleContext'
import {User, SortField, SortDirection} from '../../types'
import {
  DEFAULT_SORT_FIELD,
  DEFAULT_SORT_DIRECTION,
  DEFAULT_ENROLLMENTS_SORT_FIELD,
  DEFAULT_ENROLLMENTS_SORT_DIRECTION,
  MULTI_VALUE_SORT_FIELDS,
} from '../../util/constants'

export interface CoursePeopleQueryResponse {
  course: {
    usersConnection: {
      nodes: User[]
    }
  }
}

export interface QueryProps {
  courseId: string
  searchTerm: string
  optionId: string
  sortField: SortField
  sortDirection: SortDirection
}

const useCoursePeopleQuery = ({
  courseId,
  searchTerm,
  optionId,
  sortField = DEFAULT_SORT_FIELD,
  sortDirection = DEFAULT_SORT_DIRECTION,
}: QueryProps) => {
  const {currentUserId, allRoles} = useCoursePeopleContext()
  const shouldFetch = searchTerm === '' || searchTerm.length >= 2
  const searchTermKey = shouldFetch ? searchTerm : ''
  const allRoleIds = allRoles.map(role => role.id)
  const enrollmentRoleIds = allRoleIds.includes(optionId) ? [optionId] : undefined
  let enrollmentsSortField = DEFAULT_ENROLLMENTS_SORT_FIELD
  let enrollmentsSortDirection = DEFAULT_ENROLLMENTS_SORT_DIRECTION
  if (MULTI_VALUE_SORT_FIELDS.includes(sortField)) {
    enrollmentsSortField = sortField
    enrollmentsSortDirection = sortDirection
  }

  return useQuery({
    // currentUserId added to key so that data is refetched when swithching between Teacher and Student Views
    queryKey: [
      'course_people',
      courseId,
      currentUserId,
      searchTermKey,
      enrollmentRoleIds,
      sortField,
      sortDirection,
      enrollmentsSortField,
      enrollmentsSortDirection,
    ],
    queryFn: async () => {
      const response = await executeQuery<CoursePeopleQueryResponse>(COURSE_PEOPLE_QUERY, {
        courseId,
        searchTerm,
        enrollmentRoleIds,
        sortField,
        sortDirection,
        enrollmentsSortField,
        enrollmentsSortDirection,
      })
      return response?.course?.usersConnection?.nodes || []
    },
    enabled: shouldFetch,
    staleTime: 1000 * 60 * 1, // 1 minute
  })
}

export default useCoursePeopleQuery
