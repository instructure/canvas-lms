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

import {useMemo, useState} from 'react'
import {fetchAssignmentGroups, getNextAssignmentGroupsPage} from '../../queries/Queries'
import {useAllPages} from '@canvas/query'
import type {FetchAssignmentGroupsResponse} from '../../queries/Queries'
import type {InfiniteData} from '@tanstack/react-query'

export const useAssignmentGroupsQuery = (courseId: string) => {
  const [queryKey] = useState(['individual-gradebook-assignmentGroups', courseId])

  const result = useAllPages<
    FetchAssignmentGroupsResponse,
    unknown,
    InfiniteData<FetchAssignmentGroupsResponse>,
    (string | number)[]
  >({
    queryKey,
    queryFn: fetchAssignmentGroups,
    getNextPageParam: getNextAssignmentGroupsPage,
    initialPageParam: null,
  })

  const {data, hasNextPage, isError, isLoading} = result

  const assignmentGroups = useMemo(
    () => data?.pages.flatMap(page => page.course.assignmentGroupsConnection.nodes) ?? [],
    [data],
  )

  return {
    assignmentGroups,
    assignmentGroupsLoading: isLoading,
    assignmentGroupsSuccessful: !isError && !isLoading && !hasNextPage,
  }
}
