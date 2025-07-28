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
import React, { useCallback, useEffect, useState } from 'react'
import { SimpleSelect } from '@instructure/ui-simple-select'
import { ScreenReaderContent } from '@instructure/ui-a11y-content'
import { useScope as createI18nScope } from '@canvas/i18n'
import { IconCheckLine } from '@instructure/ui-icons'

const I18n = createI18nScope('discussions_posts')
const getSortConfig = () => {
  const options = {
    desc: () => I18n.t('Newest First'),
    asc: () => I18n.t('Oldest First'),
  }

  return options
}

interface SortFilterDropDownProps {
  isLocked: boolean
  selectedSortType: string
  onSortClick?: () => void
  width?: string
}

const SortOrderDropDown: React.FC<SortFilterDropDownProps> = ({ isLocked, selectedSortType, onSortClick, width }) => {
  const [actualSortType, setActualSortType] = useState(selectedSortType)

  useEffect(() => {
    setActualSortType(selectedSortType)
  }, [selectedSortType])

  const handleSortOrderTypeChange =
    (
      _event: React.SyntheticEvent,
      data: {
        value?: string | number
        id?: string
      },
    ) => {
      if (data.value !== actualSortType) {
        setActualSortType(data.value as string)
        if (onSortClick) {
          onSortClick()
        }
      }
    }

  return (
    <span data-testid="sort-order-dropdown">
      <SimpleSelect
        data-testid="sort-order-select"
        renderLabel={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}
        defaultValue={actualSortType}
        onChange={handleSortOrderTypeChange}
        disabled={isLocked}
        width={width}
      >
        <SimpleSelect.Group renderLabel={I18n.t('Sort by')}>
          {Object.entries(getSortConfig()).map(([viewOption, viewOptionLabel]) => (
            <SimpleSelect.Option
              data-testid={`sort-order-select-option-${viewOption}`}
              id={viewOption}
              key={viewOption}
              value={viewOption}
              renderBeforeLabel={viewOption === actualSortType ? <IconCheckLine /> : <span />}
            >
              {viewOptionLabel()}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect.Group>
      </SimpleSelect>
    </span>
  )
}

export default SortOrderDropDown
