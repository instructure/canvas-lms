// @ts-nocheck
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useRef, ReactElement, ReactNode, ChangeEvent, useEffect} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {Spinner} from '@instructure/ui-spinner'
import getLiveRegion from './liveRegion'

import type {SelectProps} from '@instructure/ui-select'

const I18n = useI18nScope('canvas_async_search_selesct')

const noOptionsId = '~~empty-option~~'

export type CanvasAsyncSelectProps = {
  inputValue?: string
  isLoading: boolean
  selectedOptionId?: string
  noOptionsLabel: string
  noOptionsValue?: string
  renderLabel?: string | ReactNode
  onOptionSelected: (event, optionId: string) => void
  onHighlightedOptionChange?: (optionId: string | null) => void
  onInputChange: (event, value) => void
  onBlur?: (event) => void
  onFocus?: (event) => void
  children?: ReactElement | ReactElement[]
  options?: any[]
  [key: string]: any
}

export default function CanvasAsyncSelect({
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  options = [],
  renderLabel = '',
  inputValue,
  isLoading = false,
  selectedOptionId,
  noOptionsLabel = '---',
  noOptionsValue = '',
  onOptionSelected = () => {},
  onHighlightedOptionChange = () => {},
  onInputChange = () => {},
  onFocus = () => {},
  onBlur = () => {},
  children = [],
  ...selectProps
}: CanvasAsyncSelectProps): ReactElement {
  const previousLoadingRef = useRef(isLoading)
  const previousLoading = previousLoadingRef.current
  const previousSelectedOptionIdRef = useRef(selectedOptionId)

  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [announcement, setAnnouncement] = useState<ReactNode>('')
  const [hasFocus, setHasFocus] = useState(false)
  const [managedInputValue, setManagedInputValue] = useState('')

  useEffect(() => {
    onHighlightedOptionChange(highlightedOptionId)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [highlightedOptionId])

  function findOptionById(id: string | undefined): ReactElement {
    let option
    React.Children.forEach(children, (c: ReactElement) => {
      if (c?.props.id === id) option = c
    })
    return option
  }

  function renderOption(option: ReactElement): ReactElement {
    const {id, renderBeforeLabel, ...optionProps} = option.props
    const props = {
      isHighlighted: id === highlightedOptionId,
      isSelected: id === selectedOptionId,
    }
    const optionChildren = option.props.children
    const renderBeforeText =
      typeof renderBeforeLabel === 'function' ? renderBeforeLabel(props) : renderBeforeLabel
    const renderChildren =
      typeof optionChildren === 'function' ? optionChildren(props) : optionChildren

    return (
      <Select.Option
        key={id}
        id={id}
        {...optionProps}
        {...props}
        renderBeforeLabel={renderBeforeText}
      >
        {renderChildren}
      </Select.Option>
    )
  }

  function renderOptions(): ReactElement | ReactElement[] {
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

  const handleInputChange: SelectProps['onInputChange'] = function (ev) {
    // user typing in the input negates the selection
    const newValue = ev.target.value
    if (typeof inputValue === 'undefined') setManagedInputValue(newValue)
    setIsShowingOptions(true)
    onInputChange(ev, newValue)
  }

  function handleShowOptions(): void {
    setIsShowingOptions(true)
  }

  function handleHideOptions(): void {
    setIsShowingOptions(false)
    setAnnouncement(I18n.t('List Collapsed'))
  }

  const handleHighlightOption: SelectProps['onRequestHighlightOption'] = function (ev, {id}) {
    const option = findOptionById(id)
    if (option) {
      setHighlightedOptionId(id ?? null)
      setAnnouncement(option.props.children)
    }
  }

  const handleSelectOption: SelectProps['onRequestSelectOption'] = function (ev, {id}) {
    const selectedOption = findOptionById(id)
    const selectedText = selectedOption?.props.children
    if (!selectedOption) return
    setIsShowingOptions(false)
    setAnnouncement(I18n.t('Option selected: %{text}. List collapsed.', {text: selectedText}))
    if (id !== noOptionsId) {
      if (typeof inputValue === 'undefined') setManagedInputValue(selectedText)
      onOptionSelected(ev, id ?? noOptionsValue)
    }
  }

  function handleFocus(ev: ChangeEvent): void {
    setHasFocus(true)
    onFocus(ev)
  }

  function handleBlur(ev: ChangeEvent): void {
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
    renderLabel,
    assistiveText: I18n.t('Type to search'),
    onFocus: handleFocus,
    onBlur: handleBlur,
    onInputChange: handleInputChange,
    onRequestShowOptions: handleShowOptions,
    onRequestHideOptions: handleHideOptions,
    onRequestHighlightOption: handleHighlightOption,
    onRequestSelectOption: handleSelectOption,
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
      <Alert liveRegion={getLiveRegion} liveRegionPoliteness="assertive" screenReaderOnly={true}>
        {announcement}
      </Alert>
    </>
  )
}

CanvasAsyncSelect.Option = Select.Option
