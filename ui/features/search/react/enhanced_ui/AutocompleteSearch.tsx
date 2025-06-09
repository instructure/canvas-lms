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
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import React, {ReactNode, useEffect, useRef, useState} from 'react'

const I18n = createI18nScope('SmartSearch')

interface Props {
  isLoading?: boolean
  defaultValue: string
  setInputRef: (input: HTMLInputElement | null) => void
  options: string[]
}

export default function AutocompleteSearch(props: Props) {
  const [inputValue, setInputValue] = useState(props.defaultValue)
  const [isShowingOptions, setIsShowingOptions] = useState<boolean>(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null)
  const [filteredOptions, setFilteredOptions] = useState<string[]>(props.options)
  const inputRef = useRef<HTMLInputElement>()

  useEffect(() => {
    setFilteredOptions(props.options)
  }, [props.options])

  useEffect(() => {
    // Reset the input value when the default value changes
    setInputValue(props.defaultValue)
  }, [props.defaultValue])

  const focusInput = () => {
    if (inputRef.current) {
      inputRef.current.blur()
      inputRef.current.focus()
    }
  }

  const getOptionById = (queryId: string) => {
    return filteredOptions[Number(queryId)]
  }

  const filterOptions = (value: string) => {
    return props.options.filter(option => option.toLowerCase().startsWith(value.toLowerCase()))
  }

  const matchValue = () => {
    // an option matching user input exists
    if (filteredOptions.length === 1) {
      const onlyOption = filteredOptions[0]
      // automatically select the matching option
      if (onlyOption.toLowerCase() === inputValue.toLowerCase()) {
        setInputValue(onlyOption)
        setSelectedOptionId('0')
        setFilteredOptions(filterOptions(''))
      }
    }
    // allow user to return to empty input and no selection
    else if (inputValue.length === 0) {
      setSelectedOptionId(null)
    }
    // no match found, return selected option label to input
    else if (selectedOptionId) {
      const selectedOption = getOptionById(selectedOptionId)
      setInputValue(selectedOption || '')
    }
    // input value is from highlighted option, not user input
    // clear input, reset options
    else if (highlightedOptionId) {
      const highlightedOption = highlightedOptionId ? getOptionById(highlightedOptionId) : undefined
      if (highlightedOption && inputValue === highlightedOption) {
        setInputValue('')
        setFilteredOptions(filterOptions(''))
      }
    }
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    matchValue()
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (event: React.SyntheticEvent, {id}: {id: string}) => {
    event.persist()
    const option = getOptionById(id)
    if (!option) return // prevent highlighting of empty option
    setHighlightedOptionId(id)
    setInputValue(event.type === 'keydown' ? option : inputValue)
  }

  const handleSelectOption = (_event: React.SyntheticEvent, {id}: {id: string}) => {
    const option = getOptionById(id)
    if (!option) return // prevent selecting of empty option
    focusInput()
    setSelectedOptionId(id)
    setIsShowingOptions(false)
    setFilteredOptions(props.options)
    setInputValue(option)
  }

  const handleInputChange = (value: string) => {
    const newOptions = filterOptions(value)
    setFilteredOptions(newOptions)
    setHighlightedOptionId(newOptions.length > 0 ? '0' : null)
    setIsShowingOptions(true)
    setSelectedOptionId(value === '' ? null : selectedOptionId)
    setInputValue(value)
  }

  const renderOptions = () => {
    const options: ReactNode[] = []
    filteredOptions.forEach((option, index) => {
      const id = index.toString()
      options.push(
        <Select.Option
          id={id}
          data-testid={`option-${option}`}
          key={id}
          isHighlighted={id === highlightedOptionId}
          isSelected={id === selectedOptionId}
        >
          {option}
        </Select.Option>,
      )
    })

    return options
  }

  return (
    <Select
      placeholder={I18n.t('Search this course')}
      inputRef={el => props.setInputRef(el)}
      data-testid="search-input"
      assistiveText="Type or use arrow keys to navigate options."
      renderLabel={<ScreenReaderContent>{I18n.t('Search')}</ScreenReaderContent>}
      renderBeforeInput={<IconSearchLine />}
      renderAfterInput={
        inputValue.length === 0 ? (
          <></>
          // rendering null/undefined still shows the arrow icon
        ) : (
          <IconButton
            withBorder={false}
            withBackground={false}
            renderIcon={<IconTroubleLine />}
            onClick={() => handleInputChange('')}
            screenReaderLabel={I18n.t('Clear search')}
          />
        )
      }
      isShowingOptions={isShowingOptions}
      inputValue={inputValue}
      onBlur={() => handleBlur()}
      onInputChange={(_e, value) => handleInputChange(value)}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={() => handleHideOptions()}
      onRequestHighlightOption={(event, data) => handleHighlightOption(event, {id: data.id || ''})}
      onRequestSelectOption={(event, data) => handleSelectOption(event, {id: data.id || ''})}
    >
      {renderOptions()}
    </Select>
  )
}
