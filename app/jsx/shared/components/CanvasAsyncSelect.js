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

import I18n from 'i18n!canvas_async_search_select'
import React, {useState, useRef} from 'react'
import {bool, func, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {Spinner} from '@instructure/ui-spinner'

const noOptionsId = '~~empty-option~~'

CanvasAsyncSelect.Option = Select.Option

CanvasAsyncSelect.propTypes = {
  ...Select.propTypes,
  inputValue: string,
  isLoading: bool,
  selectedOptionId: string,
  noOptionsLabel: string,
  onOptionSelected: func, // (event, optionId | null) => {}
  onInputChange: func // (event, value) => {}
}

CanvasAsyncSelect.defaultProps = {
  inputValue: '',
  isLoading: false,
  noOptionsLabel: '---',
  onOptionSelected: () => {},
  onInputChange: () => {}
}

export default function CanvasAsyncSelect({
  options,
  inputValue,
  isLoading,
  selectedOptionId,
  noOptionsLabel,
  onOptionSelected,
  onInputChange,
  children,
  ...selectProps
}) {
  const previousLoadingRef = useRef(isLoading)
  const previousLoading = previousLoadingRef.current
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [announcement, setAnnouncement] = useState('')
  const [hasFocus, setHasFocus] = useState(false)

  function findOptionById(id) {
    let option
    React.Children.forEach(children, c => {
      if (c.props.id === id) option = c
    })
    return option
  }

  function renderOption(option) {
    const {id, ...optionProps} = option.props
    const props = {
      isHighlighted: id === highlightedOptionId,
      isSelected: id === selectedOptionId
    }
    return (
      <Select.Option key={id} id={id} {...optionProps} {...props}>
        {option.props.children}
      </Select.Option>
    )
  }

  function renderOptions() {
    if (isLoading) {
      return (
        <Select.Option id={noOptionsId}>
          <Spinner renderTitle={I18n.t('Loading options...')} size="small" />
        </Select.Option>
      )
    } else if (React.Children.count(children) === 0) {
      return <Select.Option id={noOptionsId}>{noOptionsLabel}</Select.Option>
    } else {
      return React.Children.map(children, renderOption)
    }
  }

  function handleInputChange(ev) {
    // user typing in the input negates the selection
    const newValue = ev.target.value
    setIsShowingOptions(true)
    onInputChange(ev, newValue)
  }

  function handleShowOptions() {
    setIsShowingOptions(true)
  }

  function handleHideOptions() {
    setIsShowingOptions(false)
    setAnnouncement(I18n.t('List Collapsed'))
  }

  function handleHighlightOption(ev, {id}) {
    const option = findOptionById(id)
    if (option) {
      setHighlightedOptionId(id)
      setAnnouncement(option.props.children)
    }
  }

  function handleSelectOption(ev, {id}) {
    const selectedOption = findOptionById(id)
    if (!selectedOption) return
    setIsShowingOptions(false)
    setAnnouncement(
      <>
        {I18n.t('Option selected:')} {selectedOption.props.children} {I18n.t('List collapsed.')}
      </>
    )
    if (id !== noOptionsId) onOptionSelected(ev, id)
  }

  function handleFocus() {
    setHasFocus(true)
  }

  function handleBlur() {
    setHasFocus(false)
    setHighlightedOptionId(null)
  }

  if (hasFocus && previousLoading !== isLoading) {
    if (isLoading) {
      setAnnouncement(I18n.t('Loading options...'))
    } else {
      setAnnouncement(I18n.t('%{count} options loaded.', {count: React.Children.count(children)}))
    }
  }

  const controlledProps = {
    inputValue,
    isShowingOptions,
    assistiveText: I18n.t('Type to search'),
    onFocus: handleFocus,
    onBlur: handleBlur,
    onInputChange: handleInputChange,
    onRequestShowOptions: handleShowOptions,
    onRequestHideOptions: handleHideOptions,
    onRequestHighlightOption: handleHighlightOption,
    onRequestSelectOption: handleSelectOption
  }

  // remember previous isLoading value so we know whether we need to send announcements
  // (we can't use an effect for this because effects only run after the DOM changes)
  previousLoadingRef.current = isLoading
  return (
    <>
      <Select {...controlledProps} {...selectProps}>
        {renderOptions()}
      </Select>
      <Alert
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        liveRegionPoliteness="assertive"
        screenReaderOnly
      >
        {announcement}
      </Alert>
    </>
  )
}
