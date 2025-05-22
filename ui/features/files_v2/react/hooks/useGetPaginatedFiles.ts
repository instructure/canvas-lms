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

import {useRef, useState} from 'react'
import {keepPreviousData, useQuery} from '@tanstack/react-query'
import {File, Folder} from '../../interfaces/File'
import {
  parseLinkHeader,
  parseBookmarkFromUrl,
  generateTableUrl,
  UnauthorizedError,
} from '../../utils/apiUtils'
import {useSearchTerm} from './useSearchTerm'

const fetchFilesAndFolders = async (url: string) => {
  const response = await fetch(url)
  if (response.status === 401) {
    throw new UnauthorizedError()
  }
  if (!response.ok) {
    throw new Error()
  }
  const links = parseLinkHeader(response.headers.get('Link'))
  const rows = (await response.json()) as (File | Folder)[]
  return {rows, links}
}

type BookmarkByPage = {[key: number]: string}

export type Sort = {
  by: string
  direction: 'asc' | 'desc'
}

export type PaginatedFiles = {
  folder: Folder
  onSettled: (rows: (File | Folder)[]) => void
}

export const useGetPaginatedFiles = ({folder, onSettled}: PaginatedFiles) => {
  const {searchTerm, setSearchTerm} = useSearchTerm()
  const [sort, setSort] = useState<Sort>({
    by: 'name',
    direction: 'asc',
  })

  const [bookmarkByPage, setBookmarkByPage] = useState<BookmarkByPage>({1: ''})
  const [currentPage, setCurrentPage] = useState(1)
  const prevState = useRef('')

  const url = generateTableUrl({
    searchTerm,
    contextId: folder.context_id,
    contextType: folder.context_type.toLowerCase(),
    folderId: folder.id.toString(),
    sortBy: sort.by,
    sortDirection: sort.direction,
    pageQueryParam: bookmarkByPage[currentPage],
  })

  const query = useQuery({
    staleTime: 0,
    placeholderData: keepPreviousData,
    queryKey: [
      'files',
      {url, folderId: folder.id, searchTerm, sort, bookmarkByPage, currentPage},
    ] as const,
    queryFn: async ({queryKey}) => {
      const [, {url, folderId, searchTerm, sort, bookmarkByPage, currentPage}] = queryKey
      const state = JSON.stringify([folderId, searchTerm, sort])
      const {bookmarkState, pageState} =
        prevState.current !== state
          ? {bookmarkState: {1: ''}, pageState: 1}
          : {bookmarkState: bookmarkByPage, pageState: currentPage}
      prevState.current = state
      setBookmarkByPage(bookmarkState)
      setCurrentPage(pageState)

      const {rows, links} = await fetchFilesAndFolders(url)
      const bookmark = parseBookmarkFromUrl(links.next)
      if (bookmark && !bookmarkState[pageState + 1]) {
        setBookmarkByPage({
          ...bookmarkState,
          [pageState + 1]: bookmark,
        })
      }

      onSettled(rows)
      return rows
    },
  })

  return {
    ...query,
    page: {
      current: currentPage,
      total: Object.keys(bookmarkByPage).length,
      set: setCurrentPage,
    },
    search: {
      term: searchTerm,
      set: setSearchTerm,
    },
    sort: {
      ...sort,
      set: setSort,
    },
  }
}
