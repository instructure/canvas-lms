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

import React, {type SyntheticEvent, useState} from 'react'
import {Select} from '@instructure/ui-select'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('content_copy_redesign')

type Option = {id: string; name: string}

export const ConfiguredSelectInput = ({
  label,
  defaultInputValue = '',
  options,
  onSelect,
}: {
  label: string
  defaultInputValue?: string
  options: Array<Option>
  onSelect: (selectedId: string | null) => void
}) => {
  const [inputValue, setInputValue] = useState<string>(defaultInputValue)
  const [isShowingOptions, setIsShowingOptions] = useState<boolean>(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null)

  const getOptionById = (queryId: string) => {
    return options.find(({id}) => id === queryId)
  }

  const getOptionLabelById = (queryId: string | null) => {
    return queryId ? getOptionById(queryId)?.name || '' : ''
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (event: SyntheticEvent, {id}: {id?: string}) => {
    const convertedId = id === undefined ? null : id
    event.persist()
    setHighlightedOptionId(convertedId)
    setInputValue(event.type === 'keydown' ? getOptionLabelById(convertedId) : inputValue)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setSelectedOptionId(getOptionLabelById(selectedOptionId))
  }

  const handleSelectOption = (_: SyntheticEvent, {id}: {id?: string}) => {
    const convertedId = id === undefined ? null : id
    setSelectedOptionId(convertedId)
    setInputValue(getOptionLabelById(convertedId))
    setIsShowingOptions(false)
    onSelect(convertedId)
  }

  return (
    <Select
      renderLabel={label}
      assistiveText={I18n.t('Use arrow keys to navigate options.')}
      inputValue={inputValue}
      isShowingOptions={isShowingOptions}
      onBlur={handleBlur}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={handleHideOptions}
      onRequestHighlightOption={handleHighlightOption}
      onRequestSelectOption={handleSelectOption}
    >
      {options.map(option => {
        return (
          <Select.Option
            id={option.id}
            key={option.id}
            isHighlighted={option.id === highlightedOptionId}
            isSelected={option.id === selectedOptionId}
          >
            {option.name}
          </Select.Option>
        )
      })}
    </Select>
  )
}
