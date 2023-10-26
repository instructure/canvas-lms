/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState, useRef, useMemo} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tag} from '@instructure/ui-tag'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {IconCheckSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_create')
const liveRegion = () => document.getElementById('flash_screenreader_holder')

export const AssignedTo = ({
  initialAssignedToInformation,
  availableAssignToOptions,
  onOptionSelect,
  errorMessage,
  onOptionDismiss,
}) => {
  const [selectedOptionAssetCode, setSelectedOptionAssetCode] = useState(
    initialAssignedToInformation
  )
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionAssetCode, setHighlightedOptionAssetCode] = useState(null)
  const [announcement, setAnnouncement] = useState(null)
  const inputRef = useRef(null)

  // This is the value that is visible in the search input
  const [inputValue, setInputValue] = useState('')
  // This is the value that is used to filter out the available options
  const [currentFilterInput, setCurrentFilterInput] = useState('')

  const filterOptions = value => {
    return Object.values(availableAssignToOptions)
      .flat()
      .filter(option => option.label.toLowerCase().includes(value.toLowerCase()))
  }

  // filterOptions only occur based on user input.
  const filteredOptions = useMemo(() => {
    if (!currentFilterInput) return availableAssignToOptions

    return Object.keys(availableAssignToOptions).reduce((acc, key) => {
      acc[key] = availableAssignToOptions[key].filter(option =>
        option.label.toLowerCase().includes(currentFilterInput.toLowerCase())
      )
      return acc
    }, {})
  }, [currentFilterInput, availableAssignToOptions])

  const getOptionByAssetCode = assetCode => {
    return Object.values(availableAssignToOptions)
      .flat()
      .find(o => o?.assetCode === assetCode)
  }

  // Might rely on id
  const handleOptionSelected = assetCode => {
    setSelectedOptionAssetCode(prev => [...prev, assetCode])
    onOptionSelect(assetCode) // Notify parent
  }

  const getDefaultHighlightedOption = (newOptions = {}) => {
    const defaultOptions = Object.values(newOptions).flat()
    return defaultOptions.length > 0 ? defaultOptions[0].assetCode : null
  }

  const handleBlur = () => {
    setHighlightedOptionAssetCode(null)
  }

  // Don't highlight groups
  const handleHighlightOption = (event, {id: assetCode}) => {
    event.persist()
    const option = getOptionByAssetCode(assetCode)
    if (!option) return
    setHighlightedOptionAssetCode(assetCode)
    // Set the visible input correctly when using keyboard
    if (event.type === 'keydown') {
      setInputValue(option.label)
    } else {
      setCurrentFilterInput(inputValue)
      setInputValue(inputValue)
    }
    setAnnouncement(option.label)
  }

  const handleSelectOption = (event, {id: assetCode}) => {
    const option = getOptionByAssetCode(assetCode)
    if (!option) return

    // Check if the option is already selected
    if (selectedOptionAssetCode.includes(assetCode)) {
      return
    }

    handleOptionSelected(assetCode)
    setInputValue('')
    setCurrentFilterInput('')
    setIsShowingOptions(false)
    setAnnouncement(I18n.t('%{optionName} selected. List collapsed.', {optionName: option.label}))
  }

  const getOptionsChangedMessage = newOptions => {
    let message =
      newOptions.length !== filteredOptions.length
        ? I18n.t('%{optionCount} options available.', {optionCount: newOptions.length}) // options changed, announce new total
        : null // options haven't changed, don't announce
    if (message && newOptions.length > 0) {
      if (highlightedOptionAssetCode !== newOptions[0].assetCode) {
        const option = getOptionByAssetCode(newOptions[0].assetCode).label
        message = `${option}. ${message}`
      }
    }
    return message
  }

  // Changes that occur when the user types in the input
  const handleInputChange = event => {
    const value = event.target.value
    const newFilteredOptions = filterOptions(value)
    // Any time input is typed, the filter should change
    setCurrentFilterInput(value)
    setInputValue(value)
    setHighlightedOptionAssetCode(getDefaultHighlightedOption(newFilteredOptions))
    setIsShowingOptions(true)
    setAnnouncement(getOptionsChangedMessage(newFilteredOptions))
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
  }

  const dismissTag = (e, tagAssetCode) => {
    e.stopPropagation()
    e.preventDefault()
    const optionBeingRemoved = getOptionByAssetCode(tagAssetCode)
    const newSelection = selectedOptionAssetCode.filter(assetCode => assetCode !== tagAssetCode)
    setSelectedOptionAssetCode(newSelection)
    setHighlightedOptionAssetCode(null)
    onOptionDismiss(tagAssetCode) // Notify parent
    setAnnouncement(
      I18n.t('%{optionName} selection has been removed', {optionName: optionBeingRemoved.label})
    )
    inputRef.current.focus()
  }

  const handleKeyDown = event => {
    const BACKSPACE_KEY_CODE = 8

    // when backspace key is pressed
    if (
      inputValue === '' &&
      selectedOptionAssetCode.length > 0 &&
      event.keyCode === BACKSPACE_KEY_CODE
    ) {
      // remove last selected option, if input has no entered text
      const lastSelectedTagAssetCode = selectedOptionAssetCode[selectedOptionAssetCode.length - 1]
      const optionBeingRemoved = getOptionByAssetCode(lastSelectedTagAssetCode)
      setHighlightedOptionAssetCode(null)
      setSelectedOptionAssetCode(prevSelectedOptionId => prevSelectedOptionId.slice(0, -1))
      onOptionDismiss(lastSelectedTagAssetCode)
      setAnnouncement(
        I18n.t('%{optionName} selection has been removed', {optionName: optionBeingRemoved.label})
      )
    }
  }

  const renderTags = () => {
    return selectedOptionAssetCode.map((assetCode, index) => (
      <Tag
        dismissible={true}
        key={assetCode}
        title={I18n.t('Remove %{optionName}', {optionName: getOptionByAssetCode(assetCode).label})}
        text={getOptionByAssetCode(assetCode).label}
        margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
        onClick={e => dismissTag(e, assetCode)}
      />
    ))
  }

  const renderGroups = () => {
    return Object.keys(filteredOptions).map(key => {
      if (!filteredOptions[key]?.length) return null
      return (
        <Select.Group key={key} renderLabel={key}>
          {filteredOptions[key].map(option => {
            const isOptionSelected = selectedOptionAssetCode.includes(option.assetCode)
            // If the option is selected, show the checkmark icon
            const iconStyle = {
              opacity: isOptionSelected ? 1 : 0,
            }
            return (
              <Select.Option
                id={option.assetCode}
                key={option.assetCode}
                isHighlighted={option.assetCode === highlightedOptionAssetCode}
                data-testid="assign-to-select-option"
              >
                <View padding="none xx-small none none">
                  <IconCheckSolid style={iconStyle} />
                </View>
                {option.label}
              </Select.Option>
            )
          })}
        </Select.Group>
      )
    })
  }

  return (
    <>
      <Select
        renderLabel={I18n.t('Assign To')}
        assistiveText={I18n.t(
          'Type or use arrow keys to navigate options. Multiple selections allowed.'
        )}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        inputRef={ref => {
          inputRef.current = ref
        }}
        onBlur={handleBlur}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
        renderBeforeInput={selectedOptionAssetCode.length > 0 ? renderTags() : null}
        messages={errorMessage}
        onKeyDown={handleKeyDown}
        data-testid="assign-to-select"
      >
        {renderGroups()}
      </Select>
      {/* This condition allows tests that don't have the flash_screenreader_holder to run without having to mock the live region */}
      {liveRegion() && (
        <Alert liveRegion={liveRegion} liveRegionPoliteness="assertive" screenReaderOnly={true}>
          {announcement}
        </Alert>
      )}
    </>
  )
}

AssignedTo.propTypes = {
  initialAssignedToInformation: PropTypes.arrayOf(PropTypes.string),
  onOptionSelect: PropTypes.func,
  availableAssignToOptions: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        assetCode: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
      })
    )
  ).isRequired,
  errorMessage: PropTypes.array,
  onOptionDismiss: PropTypes.func,
}

AssignedTo.defaultProps = {
  initialAssignedToInformation: [],
  availableAssignToOptions: {
    'Master Paths': [],
    'Course Sections': [],
    Students: [],
  },
  errorMessage: [],
  onOptionSelect: () => {},
  onOptionDismiss: () => {},
}
