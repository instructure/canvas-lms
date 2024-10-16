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
import {fetchSections, getNextSectionsPage} from '../../queries/Queries'
import {useInfiniteQuery} from '@canvas/query'

export const useSectionsQuery = (courseId: string) => {
  const [queryKey] = useState(['individual-gradebook-sections', courseId])

  const {data, fetchNextPage, hasNextPage, isFetchingNextPage, isError, isLoading} =
    useInfiniteQuery({
      queryKey,
      queryFn: fetchSections,
      getNextPageParam: getNextSectionsPage,
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

  const sections = useMemo(
    () => data?.pages.flatMap(page => page.course.sectionsConnection.nodes) ?? [],
    [data]
  )

  return {
    sections,
    sectionsLoading: isLoading,
    sectionsSuccessful: !isError && !isLoading && !hasNextPage,
  }
}
