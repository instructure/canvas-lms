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
}) => {
  const [selectedOptionId, setSelectedOptionId] = useState(initialAssignedToInformation)
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [announcement, setAnnouncement] = useState(null)
  const inputRef = useRef(null)

  const filterOptions = value => {
    return Object.values(availableAssignToOptions)
      .flat()
      .filter(option => option.label.toLowerCase().includes(value.toLowerCase()))
  }

  // filterOptions only occur based on user input.
  const filteredOptions = useMemo(() => {
    if (!inputValue) return availableAssignToOptions

    return Object.keys(availableAssignToOptions).reduce((acc, key) => {
      acc[key] = availableAssignToOptions[key].filter(option =>
        option.label.toLowerCase().includes(inputValue.toLowerCase())
      )
      return acc
    }, {})
  }, [inputValue, availableAssignToOptions])

  const getOptionById = id => {
    return Object.values(availableAssignToOptions)
      .flat()
      .find(o => o?.id === id)
  }

  const handleOptionSelected = id => {
    setSelectedOptionId(prev => [...prev, id])
    onOptionSelect(id) // Notify parent
  }

  const getDefaultHighlightedOption = (newOptions = {}) => {
    const defaultOptions = Object.values(newOptions).flat()
    return defaultOptions.length > 0 ? defaultOptions[0].id : null
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  // Don't highlight groups
  const handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = getOptionById(id)
    if (!option) return
    setHighlightedOptionId(id)
    setInputValue(event.type === 'keydown' ? option.label : inputValue)
    setAnnouncement(option.label)
  }

  const handleSelectOption = (event, {id}) => {
    const option = getOptionById(id)
    if (!option) return

    // Check if the option is already selected
    if (selectedOptionId.includes(id)) {
      return
    }

    handleOptionSelected(id)
    setInputValue('')
    setIsShowingOptions(false)
    setAnnouncement(I18n.t('%{optionName} selected. List collapsed.', {optionName: option.label}))
  }

  const getOptionsChangedMessage = newOptions => {
    let message =
      newOptions.length !== filteredOptions.length
        ? I18n.t('%{optionCount} options available.', {optionCount: newOptions.length}) // options changed, announce new total
        : null // options haven't changed, don't announce
    if (message && newOptions.length > 0) {
      if (highlightedOptionId !== newOptions[0].id) {
        const option = getOptionById(newOptions[0].id).label
        message = `${option}. ${message}`
      }
    }
    return message
  }

  const handleInputChange = event => {
    const value = event.target.value
    const newFilteredOptions = filterOptions(value)
    setInputValue(value)
    setHighlightedOptionId(getDefaultHighlightedOption(newFilteredOptions))
    setIsShowingOptions(true)
    setAnnouncement(getOptionsChangedMessage(newFilteredOptions))
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
  }

  const dismissTag = (e, tag) => {
    e.stopPropagation()
    e.preventDefault()
    const newSelection = selectedOptionId.filter(id => id !== tag)
    setSelectedOptionId(newSelection)
    setHighlightedOptionId(null)
    inputRef.current.focus()
  }

  const renderTags = () => {
    return selectedOptionId.map((id, index) => (
      <Tag
        dismissible={true}
        key={id}
        title={I18n.t('Remove %{optionName}', {optionName: getOptionById(id).label})}
        text={getOptionById(id).label}
        margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
        onClick={e => dismissTag(e, id)}
      />
    ))
  }

  const renderGroups = () => {
    return Object.keys(filteredOptions).map(key => {
      if (!filteredOptions[key]?.length) return null
      return (
        <Select.Group key={key} renderLabel={key}>
          {filteredOptions[key].map(option => {
            const isOptionSelected = selectedOptionId.includes(option.id)
            // If the option is selected, show the checkmark icon
            const iconStyle = {
              opacity: isOptionSelected ? 1 : 0,
            }
            return (
              <Select.Option
                id={option.id}
                key={option.id}
                isHighlighted={option.id === highlightedOptionId}
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
        renderBeforeInput={selectedOptionId.length > 0 ? renderTags() : null}
        messages={errorMessage}
        data-testid="assign-to-select"
      >
        {renderGroups()}
      </Select>
      <Alert liveRegion={liveRegion} liveRegionPoliteness="assertive" screenReaderOnly={true}>
        {announcement}
      </Alert>
    </>
  )
}

AssignedTo.propTypes = {
  initialAssignedToInformation: PropTypes.arrayOf(PropTypes.string),
  onOptionSelect: PropTypes.func,
  availableAssignToOptions: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
      })
    )
  ).isRequired,
  errorMessage: PropTypes.array,
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
}
