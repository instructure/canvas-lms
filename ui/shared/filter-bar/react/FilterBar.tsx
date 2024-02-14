/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState, useCallback, type SyntheticEvent} from 'react'

import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconSearchLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import debounce from '@instructure/debounce'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('filter_bar')
const SEARCH_DELAY = 350

export interface FilterOption<T extends string> {
  value: T
  text: string
}

export interface FilterBarProps<T extends string> {
  /**
   * called when the filter dropdown changes
   */
  onFilter: (filter: 'all' | T) => void
  /**
   * called when the search input changes
   */
  onSearch: (query: string) => void
  /**
   * default 'All' option is always included
   */
  filterOptions: ReadonlyArray<FilterOption<T>>
  /**
   * optional screen reader content for the search input
   */
  searchScreenReaderLabel?: string
  /**
   * optional placeholder text for the search input
   */
  searchPlaceholder?: string
  /**
   * optional debounce delay for multiple search input changes. defaults to 350ms.
   */
  searchDebounceDelay?: number
}

/**
 * Provides a filter bar with a dropdown and search input.
 * Debounces search box input before calling onSearch.
 */
export default function FilterBar<T extends string>({
  onFilter,
  onSearch,
  filterOptions,
  searchScreenReaderLabel,
  searchPlaceholder,
  searchDebounceDelay = SEARCH_DELAY,
}: FilterBarProps<T>) {
  const [filter, setFilter] = useState('all')
  const [searchInput, setSearchInput] = useState('')

  const defaultOption: FilterOption<'all'> = {value: 'all', text: I18n.t('All')}
  const defaultPlaceholder: string = I18n.t('Search')

  const updateSearchQuery: (query: string) => void = useCallback(
    debounce(
      (query: string) => {
        onSearch(query)
      },
      searchDebounceDelay,
      {leading: false, trailing: true}
    ),
    [searchDebounceDelay]
  )

  const acceptSearchInput = (_e: SyntheticEvent, val: string) => {
    setSearchInput(val)
    if (val !== searchInput && val.length > 2) {
      updateSearchQuery(val)
    } else if (val.length === 0) {
      updateSearchQuery('')
    }
  }

  const updateFilter = (
    _e: SyntheticEvent,
    data: {value?: string | number | undefined; id?: string | undefined}
  ) => {
    if (typeof data.value === 'string') {
      setFilter(data.value)
      onFilter(data.value as T)
    }
  }

  const clearFilters = () => {
    setFilter('all')
    setSearchInput('')

    onFilter('all')
    onSearch('')
  }

  return (
    <Flex justifyItems="start">
      <Flex.Item padding="small">
        <SimpleSelect
          assistiveText={I18n.t('Use arrow keys to navigate options.')}
          renderLabel={<ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>}
          onChange={updateFilter}
          width="10rem"
          value={filter}
        >
          {[defaultOption, ...filterOptions].map(option => (
            <SimpleSelect.Option id={option.value} value={option.value} key={option.value}>
              {option.text}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
      <Flex.Item padding="small">
        <TextInput
          renderLabel={
            <ScreenReaderContent>
              {searchScreenReaderLabel || defaultPlaceholder}
            </ScreenReaderContent>
          }
          placeholder={searchPlaceholder || defaultPlaceholder}
          type="search"
          value={searchInput}
          onChange={acceptSearchInput}
          renderBeforeInput={<IconSearchLine inline={false} />}
          display="inline-block"
        />
      </Flex.Item>
      <Flex.Item padding="small">
        <Button color="primary" onClick={clearFilters}>
          {I18n.t('Clear')}
        </Button>
      </Flex.Item>
    </Flex>
  )
}
