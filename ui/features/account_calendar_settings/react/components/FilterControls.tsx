// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React from 'react'

import {IconButton} from '@instructure/ui-buttons'
import {
  IconSearchLine,
  IconXLine,
  IconFilterLine,
  IconFilterSolid,
  IconEyeLine,
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendar_settings_filter_controls')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Option: SimpleSelectOption} = SimpleSelect as any

export enum FilterType {
  SHOW_ALL = 'all',
  SHOW_VISIBLE = 'visible',
  SHOW_HIDDEN = 'hidden',
}

type ComponentProps = {
  readonly searchValue: string
  readonly filterValue: FilterType
  readonly setSearchValue: (searchQuery: string) => void
  readonly setFilterValue: (filterType: FilterType) => void
}

const FILTER_OPTIONS = [
  {id: FilterType.SHOW_ALL, value: FilterType.SHOW_ALL, name: I18n.t('Show all')},
  {
    id: FilterType.SHOW_VISIBLE,
    value: FilterType.SHOW_VISIBLE,
    name: I18n.t('Show only enabled calendars'),
  },
  {
    id: FilterType.SHOW_HIDDEN,
    value: FilterType.SHOW_HIDDEN,
    name: I18n.t('Show only disabled calendars'),
  },
]

export const FilterControls = ({
  searchValue,
  filterValue,
  setSearchValue,
  setFilterValue,
}: ComponentProps) => {
  const clearSearchButton = (
    <IconButton
      renderIcon={IconXLine}
      type="reset"
      withBackground={false}
      withBorder={false}
      size="small"
      screenReaderLabel={I18n.t('Clear search')}
      onClick={() => setSearchValue('')}
    />
  )

  return (
    <View as="div" margin="medium">
      <TextInput
        renderLabel={<ScreenReaderContent>{I18n.t('Search Calendars')}</ScreenReaderContent>}
        type="search"
        placeholder={I18n.t('Search Calendars')}
        renderBeforeInput={IconSearchLine}
        renderAfterInput={searchValue?.length ? clearSearchButton : undefined}
        themeOverride={{
          borderRadius: '2rem',
        }}
        value={searchValue}
        onChange={(_, value) => setSearchValue(value)}
      />

      <View as="div" margin="small 0 0">
        <View margin="0 x-small">
          {filterValue === FilterType.SHOW_ALL ? <IconFilterLine /> : <IconFilterSolid />}
        </View>
        <SimpleSelect
          data-testid="account-filter-dropdown"
          renderLabel={<ScreenReaderContent>{I18n.t('Filter Calendars')}</ScreenReaderContent>}
          renderBeforeInput={IconEyeLine}
          value={filterValue}
          size="small"
          width="18rem"
          isInline={true}
          onChange={(_, data) => {
            const {value} = data
            if (!Object.values(FilterType).includes(value as FilterType))
              throw new RangeError(`Unexpected filter type "${value}!`)
            setFilterValue(value as FilterType)
          }}
        >
          {FILTER_OPTIONS.map(option => (
            <SimpleSelectOption
              id={option.id}
              value={option.value}
              key={`filter_option_${option.id}`}
            >
              {option.name}
            </SimpleSelectOption>
          ))}
        </SimpleSelect>
      </View>
    </View>
  )
}
