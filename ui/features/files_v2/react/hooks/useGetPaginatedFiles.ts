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

import {useRef, useState, useEffect} from 'react'
import {keepPreviousData, useQuery} from '@tanstack/react-query'
import {File, Folder} from '../../interfaces/File'
import {
  parseLinkHeader,
  parseBookmarkFromUrl,
  generateTableUrl,
  doFetchApiWithAuthCheck,
} from '../../utils/apiUtils'
import {useSearchTerm} from './useSearchTerm'

export const PER_PAGE = 25

const fetchFilesAndFolders = async (url: string) => {
  const {json, response} = await doFetchApiWithAuthCheck<(File | Folder)[]>({
    path: url,
  })
  const links = parseLinkHeader(response.headers.get('Link'))
  const totalItems = Number(response.headers.get('X-Total-Items')) || 0
  return {rows: json!, links, totalItems}
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
  const {searchTerm, urlEncodedSearchTerm, setSearchTerm} = useSearchTerm()
  const [sort, setSort] = useState<Sort>({
    by: 'name',
    direction: 'asc',
  })
  const [totalItems, setTotalItems] = useState(0)
  const [bookmarkByPage, setBookmarkByPage] = useState<BookmarkByPage>({1: ''})
  const [currentPage, setCurrentPage] = useState(1)
  const prevState = useRef('')

  const isSingleCharSearch = searchTerm?.trim().length === 1
  const url = isSingleCharSearch
    ? ''
    : generateTableUrl({
        searchTerm: urlEncodedSearchTerm,
        contextId: folder.context_id,
        contextType: folder.context_type.toLowerCase(),
        folderId: folder.id,
        sortBy: sort.by,
        sortDirection: sort.direction,
        pageQueryParam: bookmarkByPage[currentPage],
        perPage: PER_PAGE,
      })

  useEffect(() => {
    setBookmarkByPage({1: ''})
    setCurrentPage(1)
  }, [folder.id, searchTerm, sort])

  const query = useQuery({
    staleTime: 0,
    placeholderData: keepPreviousData,
    queryKey: ['files', {url, currentPage, isSingleCharSearch}] as const,
    queryFn: async ({queryKey}) => {
      const [, {url, currentPage, isSingleCharSearch}] = queryKey

      // Return empty results for single character searches
      if (isSingleCharSearch) {
        onSettled([])
        return []
      }

      const {rows, links, totalItems} = await fetchFilesAndFolders(url)
      setTotalItems(totalItems)
      const bookmark = parseBookmarkFromUrl(links.next)
      setBookmarkByPage(prev => {
        if (bookmark && !prev[currentPage + 1]) {
          return {
            ...prev,
            [currentPage + 1]: bookmark,
          }
        }
        return prev
      })

      onSettled(rows)
      return rows
    },
  })

  return {
    ...query,
    page: {
      current: currentPage,
      totalItems,
      totalPages: Math.ceil(totalItems / PER_PAGE),
      next: () => setCurrentPage(prev => prev + 1),
      prev: () => setCurrentPage(prev => Math.max(prev - 1, 1)),
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
