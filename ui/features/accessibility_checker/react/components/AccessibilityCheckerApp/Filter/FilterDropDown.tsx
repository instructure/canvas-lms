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
import CanvasMultiSelect from '@canvas/multi-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FilterOption} from '../../../types'

const I18n = createI18nScope('accessibility_checker')

const ALL_OPTION: FilterOption = {value: 'all', label: I18n.t('All')}

const FilterDropDown = ({
  label,
  options,
  selected,
  onChange,
  dataTestId,
}: {
  label: string
  options: {value: string; label: string}[]
  selected: FilterOption[]
  onChange: (value: FilterOption[]) => void
  dataTestId?: string
}) => {
  const enhancedOptions = [ALL_OPTION, ...options]

  const handleChange = (selectedOptionIds: string[]) => {
    const filteredOptions = options.filter(option => selectedOptionIds.includes(option.value))
    if (
      filteredOptions.some(option => option.value === 'all') &&
      !selected.some(option => option.value === 'all')
    ) {
      onChange([ALL_OPTION])
    } else if (
      !filteredOptions.some(option => option.value === 'all') &&
      selected.some(option => option.value === 'all')
    ) {
      onChange(filteredOptions)
    } else if (
      filteredOptions.some(option => option.value === 'all') &&
      filteredOptions.length > 1
    ) {
      onChange(filteredOptions.filter(option => option.value !== 'all'))
    } else {
      onChange(filteredOptions)
    }
  }

  return (
    <CanvasMultiSelect
      data-testid={dataTestId}
      label={label}
      selectedOptionIds={selected.map(option => option.value)}
      onChange={(ids: string[]) => handleChange(ids)}
    >
      {enhancedOptions.map(({value, label}) => (
        <CanvasMultiSelect.Option key={value} id={value} value={value} label={label}>
          {label}
        </CanvasMultiSelect.Option>
      ))}
    </CanvasMultiSelect>
  )
}

export default FilterDropDown
