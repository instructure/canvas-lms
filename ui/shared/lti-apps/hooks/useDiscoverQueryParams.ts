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

import {useCallback, useMemo} from 'react'
import {useSearchParams} from 'react-router-dom'
import type {LtiFilters} from '../models/Filter'

export type DiscoverParams = {
  search: string
  page: number
  filters: LtiFilters
}

const useDiscoverQueryParams = () => {
  const [searchParams, setSearchParams] = useSearchParams()

  const parseUrlParams = (params: URLSearchParams): DiscoverParams => {
    let search = ''
    let page = 1
    let filters: LtiFilters = {}

    try {
      search = params.get('search') || ''
      page = parseInt(params.get('page') || '1', 10)
      filters = JSON.parse(params.get('filters') || '{}')
    } catch (error) {
       
      console.error('Error parsing URL params', error)
    }
    return {search, page, filters}
  }

  const queryParams = useMemo((): DiscoverParams => parseUrlParams(searchParams), [searchParams])

  const setQueryParams = useCallback(
    (params: Partial<DiscoverParams>) => {
      const {search, page, filters} = params
      const currentHash = window.location.hash

      setSearchParams({
        search: search ?? '',
        page: page?.toString() ?? '',
        filters: JSON.stringify(filters) ?? '',
      })

      if (currentHash) {
        window.location.hash = currentHash
      }
    },
    [setSearchParams],
  )

  const updateQueryParams = useCallback(
    (params: Partial<DiscoverParams>) => {
      const oldParams = new URLSearchParams(window.location.search)
      const {search, page, filters} = parseUrlParams(oldParams)
      const currentHash = window.location.hash

      setSearchParams({
        search: params.search ?? search,
        page: params.page?.toString() ?? page.toString(),
        filters: JSON.stringify(params.filters ?? filters) ?? '',
      })

      if (currentHash) {
        window.location.hash = currentHash
      }
    },
    [setSearchParams],
  )

  return {queryParams, setQueryParams, updateQueryParams}
}

export default useDiscoverQueryParams
