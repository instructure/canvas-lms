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

import {useState, useEffect, useCallback, ChangeEvent} from 'react'
import {useDebouncedCallback} from 'use-debounce'

export interface UseSearchResult {
  search: string
  debouncedSearch: string
  onChangeHandler: (event: ChangeEvent<HTMLInputElement>) => void
  onClearHandler: () => void
}

const useSearch = (debounceTime: number = 500): UseSearchResult => {
  const [search, setSearch] = useState<string>('')
  const [debouncedSearch, setDebouncedSearch] = useState<string>('')

  const debouncedCallback = useDebouncedCallback((value: string) => {
    setDebouncedSearch(value)
  }, debounceTime)

  const onChangeHandler = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setSearch(event?.target?.value || '')
  }, [])

  const onClearHandler = useCallback(() => {
    setSearch('')
    setDebouncedSearch('')
  }, [])

  useEffect(() => {
    debouncedCallback(search)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  return {
    search,
    debouncedSearch,
    onChangeHandler,
    onClearHandler,
  }
}

export default useSearch
