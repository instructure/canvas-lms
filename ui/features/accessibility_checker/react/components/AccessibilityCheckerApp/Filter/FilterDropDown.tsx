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

import CanvasMultiSelect from '@canvas/multi-select'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

const FilterDropDown = ({
  label,
  options,
  selected,
  onChange,
  dataTestId,
}: {
  label: string
  options: {value: string; label: string}[]
  selected: string[]
  onChange: (value: string[]) => void
  dataTestId?: string
}) => {
  const allOption = {value: 'all', label: I18n.t('All')}
  const enhancedOptions = [allOption, ...options]

  const handleChange = (selectedOptionIds: string[]) => {
    if (selectedOptionIds.includes('all') && !selected.includes('all')) {
      onChange(['all'])
    } else if (!selectedOptionIds.includes('all') && selected.includes('all')) {
      onChange(selectedOptionIds)
    } else if (selectedOptionIds.includes('all') && selectedOptionIds.length > 1) {
      onChange(selectedOptionIds.filter(id => id !== 'all'))
    } else {
      onChange(selectedOptionIds)
    }
  }

  return (
    <CanvasMultiSelect
      data-testid={dataTestId}
      label={label}
      selectedOptionIds={selected}
      onChange={handleChange}
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
