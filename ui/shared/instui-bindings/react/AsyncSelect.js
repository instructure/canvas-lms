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
  noOptionsValue: string, // value for selected option when no or invalid selection
  onOptionSelected: func, // (event, optionId | null) => {}
  onInputChange: func, // (event, value) => {}
  onBlur: func,
  onFocus: func
}

// NOTE:
// If the inputValue prop is not specified, this component will control the inputValue
// of <Select> itself. If it is specified, it is the caller's responsibility to manage
// its value in response to input changes!

CanvasAsyncSelect.defaultProps = {
  isLoading: false,
  noOptionsLabel: '---',
  noOptionsValue: '',
  onOptionSelected: Function.prototype,
  onInputChange: Function.prototype,
  onBlur: Function.prototype,
  onFocus: Function.prototype
}

export default function CanvasAsyncSelect({
  options,
  inputValue,
  isLoading,
  selectedOptionId,
  noOptionsLabel,
  noOptionsValue,
  onOptionSelected,
  onInputChange,
  onFocus,
  onBlur,
  children,
  ...selectProps
}) {
  const previousLoadingRef = useRef(isLoading)
  const previousLoading = previousLoadingRef.current
  const previousSelectedOptionIdRef = useRef(selectedOptionId)

  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [announcement, setAnnouncement] = useState('')
  const [hasFocus, setHasFocus] = useState(false)
  const [managedInputValue, setManagedInputValue] = useState('')

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
          <Spinner renderTitle={I18n.t('Loading options...')} size="x-small" />
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
    if (typeof inputValue === 'undefined') setManagedInputValue(newValue)
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
    const selectedText = selectedOption?.props.children
    if (!selectedOption) return
    setIsShowingOptions(false)
    setAnnouncement(
      <>
        {I18n.t('Option selected:')} {selectedText} {I18n.t('List collapsed.')}
      </>
    )
    if (id !== noOptionsId) {
      if (typeof inputValue === 'undefined') setManagedInputValue(selectedText)
      onOptionSelected(ev, id)
    }
  }

  function handleFocus(ev) {
    setHasFocus(true)
    onFocus(ev)
  }

  function handleBlur(ev) {
    setHasFocus(false)
    setHighlightedOptionId(null)
    // if we're managing our own input value and all our possible options just
    // went away, be sure to notify the parent the the selection has gone away
    // as well.
    if (React.Children.count(children) === 0 && typeof inputValue === 'undefined') {
      setManagedInputValue('')
      onOptionSelected(ev, noOptionsValue)
    }
    onBlur(ev)
  }

  if (hasFocus && previousLoading !== isLoading) {
    if (isLoading) {
      setAnnouncement(I18n.t('Loading options...'))
    } else {
      setAnnouncement(I18n.t('%{count} options loaded.', {count: React.Children.count(children)}))
    }
  }

  // If we're controlling our own inputValue, take care to clear it if the selection resets
  // out from under us.
  if (
    typeof inputValue === 'undefined' &&
    selectedOptionId !== previousSelectedOptionIdRef.current &&
    !selectedOptionId
  ) {
    setManagedInputValue('')
  }

  const controlledProps = {
    inputValue: typeof inputValue === 'undefined' ? managedInputValue : inputValue,
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
  previousSelectedOptionIdRef.current = selectedOptionId
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
