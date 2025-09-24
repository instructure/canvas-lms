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

import React, {useEffect, useState} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useDebouncedCallback} from 'use-debounce'

const I18n = createI18nScope('accessibility_checker')

interface SearchIssueProps {
  onSearchChange: (value: string) => void
}

export const SearchIssue: React.FC<SearchIssueProps> = ({onSearchChange}) => {
  const [search, setSearch] = useState<string>('')

  useEffect(() => {
    const queryString = window.location.search
    const params = new URLSearchParams(queryString)
    const searchQuery = params.get('search')
    if (searchQuery) {
      setSearch(searchQuery)
    }
  }, [])

  const debouncedOnSearchChange = useDebouncedCallback((value: string) => {
    onSearchChange(value)
  }, 300)

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newSearch = event.target.value
    setSearch(newSearch)
    debouncedOnSearchChange(newSearch)
  }

  return (
    <TextInput
      id="issueSearchInput"
      value={search}
      renderBeforeInput={() => <IconSearchLine inline={false} />}
      renderLabel={''}
      onChange={handleSearchChange}
      placeholder={I18n.t('Search...')}
      width="100%"
    />
  )
}
