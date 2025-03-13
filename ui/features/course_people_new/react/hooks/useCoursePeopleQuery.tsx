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
import {executeQuery} from '@canvas/query/graphql'
import useCoursePeopleContext from './useCoursePeopleContext'
import type {User} from '../../types'

export interface CoursePeopleQueryResponse{
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
}

const useCoursePeopleQuery = ({
  courseId,
  searchTerm,
  optionId
}: QueryProps) => {
  const {currentUserId, allRoles} = useCoursePeopleContext()
  const shouldFetch = searchTerm === '' || searchTerm.length >= 2
  const searchTermKey = shouldFetch ? searchTerm : ''
  const allRoleIds = allRoles.map(role => role.id)
  const enrollmentRoleIds = allRoleIds.includes(optionId) ? [optionId] : undefined

  return useQuery({
    // currentUserId added to key so that data is refetched when swithching between Teacher and Student Views
    queryKey: ['course_people', courseId, currentUserId, searchTermKey, enrollmentRoleIds],
    queryFn: async () => {
      const response = await executeQuery<CoursePeopleQueryResponse>(
        COURSE_PEOPLE_QUERY,
        {
          courseId,
          searchTerm,
          enrollmentRoleIds
        }
      )
      return response?.course?.usersConnection?.nodes || []
    },
    enabled: shouldFetch
  })
}

export default useCoursePeopleQuery
