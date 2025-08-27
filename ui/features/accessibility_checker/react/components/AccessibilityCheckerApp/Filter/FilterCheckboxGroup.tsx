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

import {useCallback, useMemo} from 'react'
import {Checkbox, CheckboxGroup, CheckboxGroupProps} from '@instructure/ui-checkbox'

import {useScope as createI18nScope} from '@canvas/i18n'

import {FilterOption} from '../../../types'

const I18n = createI18nScope('accessibility_checker')

const ALL_OPTION: FilterOption = {value: 'all', label: I18n.t('All')}

type FilterCheckboxGroupProps = CheckboxGroupProps & {
  options: {value: string; label: string}[]
  selected: FilterOption[]
  onUpdate: (value: FilterOption[]) => void
}

const FilterCheckboxGroup = ({
  options,
  selected,
  onUpdate,
  ...checkboxGroupProps
}: FilterCheckboxGroupProps) => {
  const handleUpdate = useCallback(
    (selectedOptionIds: (string | number)[]) => {
      // Current state
      const currentAllSelected = selected.some(option => option.value === 'all')
      const currentSelectedRegularOptions = selected.filter(option => option.value !== 'all')
      const currentAllRegularOptionsSelected =
        currentSelectedRegularOptions.length === options.length

      // New state
      const newAllSelected = selectedOptionIds.includes('all')
      const newSelectedRegularOptions = selectedOptionIds.filter(id => id !== 'all')
      const newAllRegularOptionsSelected = newSelectedRegularOptions.length === options.length

      if (newAllSelected && !currentAllSelected) {
        // "All" was just checked
        onUpdate([ALL_OPTION])
      } else if (!newAllSelected && currentAllSelected) {
        // "All" was just unchecked, uncheck all options
        onUpdate([])
      } else if (newAllRegularOptionsSelected && !currentAllRegularOptionsSelected) {
        // All regular options are now selected, automatically check "All"
        onUpdate([ALL_OPTION])
      } else {
        // Regular option selection/deselection
        const selectedOptions = options.filter(option =>
          newSelectedRegularOptions.includes(option.value),
        )
        onUpdate(selectedOptions)
      }
    },
    [onUpdate, options, selected],
  )

  const checkboxValues = useMemo(() => {
    // If "All" is selected, return all option values
    if (selected.some(option => option.value === 'all')) {
      return ['all', ...options.map(option => option.value)]
    }

    return selected.map(option => option.value)
  }, [selected, options])

  const enhancedOptions = useMemo(() => {
    return [ALL_OPTION, ...options]
  }, [options])

  return (
    <CheckboxGroup {...checkboxGroupProps} onChange={handleUpdate} value={checkboxValues}>
      {enhancedOptions.map(({value, label}) => (
        <Checkbox key={value} value={value} label={label}>
          {label}
        </Checkbox>
      ))}
    </CheckboxGroup>
  )
}

export default FilterCheckboxGroup
