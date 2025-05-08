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

import {useMemo} from 'react'
import {fetchOutcomes, getNextOutcomesPage} from '../../queries/Queries'
import {useAllPages} from '@canvas/query'
import type {InfiniteData} from '@tanstack/react-query'
import type {FetchOutcomesResponse} from '../../queries/Queries'

export const useOutcomesQuery = (courseId: string) => {
  const queryKey: [string, string] = ['individual-gradebook-outcomes', courseId]

  const {data, hasNextPage, isError, isLoading} = useAllPages<
    FetchOutcomesResponse,
    Error,
    InfiniteData<FetchOutcomesResponse>,
    [string, string]
  >({
    queryKey,
    queryFn: fetchOutcomes,
    getNextPageParam: getNextOutcomesPage,
    initialPageParam: null,
  })

  const outcomes = useMemo(
    () => data?.pages.flatMap(page => page.course.rootOutcomeGroup.outcomes.nodes) ?? [],
    [data],
  )

  return {
    outcomes,
    outcomesLoading: isLoading,
    outcomesSuccessful: !isError && !isLoading && !hasNextPage,
  }
}
