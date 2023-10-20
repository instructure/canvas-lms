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

import type {SelectProps} from '@instructure/ui-select'

const I18n = useI18nScope('groupNavigationSelector')

type GroupOption = {
  id: string
  label: string
}

type Props = {
  options: GroupOption[]
}

const getOptionById = (options: GroupOption[], queryId: string): GroupOption => {
  const option = options.find(opt => opt.id === queryId)
  if (!option) {
    throw new Error('No option found for id: ' + queryId)
  }
  return option
}

export default function GroupNavigationSelector(props: Props) {
  const defaultOption = getOptionById(props.options, window.location.pathname.split('/')[2])
  const [isShowingOptions, setIsShowingOptions] = useState<boolean>(false)
  const [selectedOptionId, setSelectedOptionId] = useState<string>(defaultOption.id)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [inputValue, setInputValue] = useState<string>(defaultOption.label)

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHideOptions = () => {
    const option = getOptionById(props.options, selectedOptionId).label
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setInputValue(selectedOptionId ? option : '')
  }

  const handleHighlightOption: SelectProps['onRequestHighlightOption'] = (event, {id}) => {
    if (typeof id === 'undefined') throw new Error('id in handleHighlightOption is undefined')
    event.persist()
    const option = getOptionById(props.options, id)
    const label = option.label
    setHighlightedOptionId(id)
    setInputValue(event.type === 'keydown' ? label : inputValue)
  }

  const handleSelectOption: SelectProps['onRequestSelectOption'] = (_event, {id}) => {
    if (typeof id === 'undefined') throw new Error('id in handleSelectOption is undefined')
    const option = getOptionById(props.options, id)
    const label = option.label
    setSelectedOptionId(id)
    setInputValue(label)
    setIsShowingOptions(false)
    const path = window.location.pathname.split('/')
    path[2] = id

    // we don't want anything after index 4 (i.e. a specific discussion or announcement)
    const newPath = path.length >= 5 ? path.slice(0, 4) : path
    // @ts-expect-error
    window.location = newPath.join('/')
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
        {props.options.map((option: GroupOption) => {
          return (
            <Select.Option
              data-testid={`group-id-${option.id}`}
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
