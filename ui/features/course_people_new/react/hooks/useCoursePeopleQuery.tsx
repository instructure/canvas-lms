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

type CoursePeopleQueryResponse = {
  course: {
    usersConnection: {
      nodes: User[]
    }
  }
}

const useCoursePeopleQuery = ({courseId}: {courseId: string}) => {
  const {currentUserId} = useCoursePeopleContext()
  
  return useQuery({
    // currentUserId added to key so that data is refetched when swithching between Teacher and Student Views
    queryKey: ['course_people', courseId, currentUserId],
    queryFn: async () => {
      const response = await executeQuery<CoursePeopleQueryResponse>(COURSE_PEOPLE_QUERY, {courseId})
      return response?.course?.usersConnection?.nodes || []
    }
  })
}

export default useCoursePeopleQuery
