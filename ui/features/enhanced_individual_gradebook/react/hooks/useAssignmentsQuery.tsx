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

import {useEffect, useMemo, useState} from 'react'
import {useInfiniteQuery} from '@canvas/query'
import {fetchAssignments, getNextAssignmentsPage} from '../../queries/Queries'
import _ from 'lodash'

export const useAssignmentsQuery = (courseId: string) => {
  const [queryKey] = useState(['individual-gradebook-assignments', courseId])

  const {data, fetchNextPage, hasNextPage, isFetchingNextPage, isError, isLoading} =
    useInfiniteQuery({
      queryKey,
      queryFn: fetchAssignments,
      getNextPageParam: getNextAssignmentsPage,
      meta: {
        fetchAtLeastOnce: true,
      },
    })

  useEffect(() => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage({
        cancelRefetch: true,
      })
    }
  }, [hasNextPage, isFetchingNextPage, fetchNextPage])

  const flatAssignments = useMemo(
    () => data?.pages.flatMap(page => page.course.assignmentsConnection.nodes) ?? [],
    [data]
  )
  const assignments = useMemo(
    () => _.groupBy(flatAssignments, 'assignmentGroupId'),
    [flatAssignments]
  )

  return {
    assignments,
    assignmentsLoading: isLoading,
    assignmentsSuccessful: !isError && !isLoading && !hasNextPage,
  }
}
