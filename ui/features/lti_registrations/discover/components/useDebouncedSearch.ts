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

import {useState, useCallback, useEffect} from 'react'
import type {ChangeEvent} from 'react'
import {useDebounce} from 'react-use'
import type {DiscoverParams} from './useDiscoverQueryParams'

const useDebouncedSearch = (props: {
  initialValue: string
  delay: number
  updateQueryParams: (params: Partial<DiscoverParams>) => void
}) => {
  const {initialValue, delay, updateQueryParams} = props
  const [searchValue, setSearchValue] = useState(initialValue)

  const [,] = useDebounce(
    () => {
      updateQueryParams({search: searchValue, page: 1})
    },
    delay,
    [searchValue]
  )

  const handleSearchInputChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setSearchValue(value)
  }, [])

  useEffect(() => {
    setSearchValue(initialValue)
  }, [initialValue])

  return {searchValue, handleSearchInputChange}
}

export default useDebouncedSearch
