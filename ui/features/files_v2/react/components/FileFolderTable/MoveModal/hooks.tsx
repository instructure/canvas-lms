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

import {useMemo} from 'react'
import {useAllPages} from '@canvas/query'
import {parseAllPagesResponse} from './utils'
import {fetchFolders, type MultiPageResponse} from '../../../queries/folders'

export const useFoldersQuery = (openedFolderID: string) => {
  const {data, hasNextPage, isLoading, isError} = useAllPages({
    queryKey: ['folders', openedFolderID] as const,
    queryFn: async ({ queryKey, pageParam }) => {
      const [_key, openedFolderID] = queryKey
      return fetchFolders(openedFolderID, pageParam)
    },
    getNextPageParam: (lastPage) => lastPage.nextPage,
    refetchOnMount: "always",
    meta: {
      fetchAtLeastOnce: true,
    },
  })

  const folders = useMemo(
    () => data ? parseAllPagesResponse(data as MultiPageResponse) : null,
    [data],
  )

  return {
    folders,
    foldersLoading: isLoading || hasNextPage,
    foldersError: isError,
  }
}
