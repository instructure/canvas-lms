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

import React from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import useInsightStore from '../../hooks/useInsightStore'

const I18n = createI18nScope('discussions_insights')

const filterOptions = [
  {value: 'all', label: I18n.t('All')},
  {value: 'relevant', label: I18n.t('Relevant')},
  {value: 'needs_review', label: I18n.t('Needs Review')},
  {value: 'irrelevant', label: I18n.t('Irrelevant')},
]

const FilterDropDown = () => {
  const filterType = useInsightStore(state => state.filterType)
  const setFilterType = useInsightStore(state => state.setFilterType)

  const handleSortOrderTypeChange = (
    _event: React.SyntheticEvent,
    data: {
      value?: string | number
      id?: string
    },
  ) => {
    setFilterType(data.value as string)
  }

  return (
    <SimpleSelect
      data-testid="filter-select"
      renderLabel={<ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>}
      defaultValue={filterType}
      onChange={handleSortOrderTypeChange}
    >
      <SimpleSelect.Group renderLabel={I18n.t('Filter by')}>
        {filterOptions.map(({value, label}) => (
          <SimpleSelect.Option
            data-testid={`filter-select-option-${value}`}
            id={value}
            key={value}
            value={value}
          >
            {label}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect.Group>
    </SimpleSelect>
  )
}

export default FilterDropDown
