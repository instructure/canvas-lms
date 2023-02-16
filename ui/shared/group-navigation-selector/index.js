/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// code in this file is stuff that needs to run on every page but that should
// not block anything else from loading. It will be loaded by webpack as an
// async chunk so it will always be loaded eventually, but not necessarily before
// any other js_bundle code runs. and by moving it into an async chunk,
// the critical code to display a page will be executed sooner

import React, {useState} from 'react'

import {Select} from '@instructure/ui-select'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('groupNavigationSelector')

const getOptionById = (options, queryId) => {
  return options.find(opt => opt.id === queryId)
}

export const GroupNavigationSelector = props => {
  const defaultOption = getOptionById(props.options, window.location.pathname.split('/')[2])
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [selectedOptionId, setSelectedOptionId] = useState(defaultOption.id)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [inputValue, setInputValue] = useState(defaultOption.label)

  const handleShowOptions = _event => {
    setIsShowingOptions(true)
  }

  const handleBlur = _event => {
    setHighlightedOptionId(null)
  }

  const handleHideOptions = _event => {
    const option = getOptionById(props.options, selectedOptionId).label
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setInputValue(selectedOptionId ? option : '')
  }

  const handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = getOptionById(props.options, id).label
    setHighlightedOptionId(id)
    setInputValue(event.type === 'keydown' ? option : inputValue)
  }

  const handleSelectOption = (_event, {id}) => {
    const option = getOptionById(props.options, id).label
    setSelectedOptionId(id)
    setInputValue(option)
    setIsShowingOptions(false)
    const path = window.location.pathname.split('/')
    path[2] = id
    window.location = path.join('/')
  }

  return (
    <View as="div" padding="0 0 medium 0">
      <Select
        data-testid="group-selector"
        renderLabel={I18n.t('Select Group')}
        assistiveText={I18n.t('Use arrow keys to navigate options.')}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        onBlur={handleBlur}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
      >
        {props.options.map(option => {
          return (
            <Select.Option
              id={option.id}
              key={option.id}
              isHighlighted={option.id === highlightedOptionId}
              isSelected={option.id === selectedOptionId}
            >
              {option.label}
            </Select.Option>
          )
        })}
      </Select>
    </View>
  )
}
