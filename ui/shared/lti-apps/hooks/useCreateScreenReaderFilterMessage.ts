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
import {useMemo, useState, useEffect} from 'react'
import type {DiscoverParams} from '../hooks/useDiscoverQueryParams'

const useCreateScreenReaderFilterMessage = (props: {
  queryParams: DiscoverParams
  isFilterApplied: boolean
  isLoading: boolean
}) => {
  const {queryParams, isFilterApplied, isLoading} = props
  const [screenReaderFilterMessage, setScreenReaderFilterMessage] = useState('')

  const concatStrings = useMemo(() => {
    const base = 'results filtered by'
    const searchterm = queryParams.search
    const filtersText = Object.values(queryParams.filters)
      .map(filterType => {
        return filterType.length > 0 ? filterType.map(filter => filter.name).join(', ') : ''
      })
      .filter(result => result !== '')
      .join(', ')

    return `${base}${searchterm ? ` search ${searchterm},` : ''}${
      filtersText ? ` using filters: ${filtersText}` : ''
    }`
  }, [queryParams])

  useEffect(() => {
    if (isFilterApplied && !isLoading) {
      setScreenReaderFilterMessage(concatStrings)
    }
  }, [isFilterApplied, isLoading, queryParams, concatStrings])

  return screenReaderFilterMessage
}

export default useCreateScreenReaderFilterMessage
