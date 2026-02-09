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

import React, {useState, useRef, useMemo, useEffect, useCallback, useContext} from 'react'
import PropTypes from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tag} from '@instructure/ui-tag'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {IconCheckSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {DiscussionDueDatesContext} from '../../util/constants'

const I18n = createI18nScope('discussion_create')
const liveRegion = () => document.getElementById('flash_screenreader_holder')

export const AssignedTo = ({
  // @ts-expect-error TS7031 (typescriptify)
  dueDateId,
  // @ts-expect-error TS7031 (typescriptify)
  initialAssignedToInformation,
  // @ts-expect-error TS7031 (typescriptify)
  availableAssignToOptions,
  // @ts-expect-error TS7031 (typescriptify)
  onOptionSelect,
  // @ts-expect-error TS7031 (typescriptify)
  onOptionDismiss,
}) => {
  const [selectedOptionAssetCode, setSelectedOptionAssetCode] = useState(
    initialAssignedToInformation,
  )
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionAssetCode, setHighlightedOptionAssetCode] = useState(null)
  const [announcement, setAnnouncement] = useState(null)
  const [errorMessage, setErrorMessage] = useState([])
  const inputRef = useRef(null)

  // This is the value that is visible in the search input
  const [inputValue, setInputValue] = useState('')
  // This is the value that is used to filter out the available options
  const [currentFilterInput, setCurrentFilterInput] = useState('')

  const [activeOptions, setActiveOptions] = useState(
    Object.values(availableAssignToOptions)
      .flat()
      // @ts-expect-error TS18046 (typescriptify)
      .find(option => initialAssignedToInformation.includes(option.assetCode)) || [],
  )

  // @ts-expect-error TS2339 (typescriptify)
  const {groupCategoryId, groups, gradedDiscussionRefMap, setGradedDiscussionRefMap} =
    useContext(DiscussionDueDatesContext)

  // Add the checkmark icon to the selected options
  // @ts-expect-error TS7006 (typescriptify)
  const addIconToOption = (option, isSelected) => ({
    ...option,
    renderBeforeLabel: <IconCheckSolid style={{opacity: isSelected ? 1 : 0}} />,
  })

  const getOptionByAssetCode = useCallback(
    // @ts-expect-error TS7006 (typescriptify)
    assetCode => {
      const returnOption = Object.values(availableAssignToOptions)
        .flat()
        // @ts-expect-error TS2339 (typescriptify)
        .find(o => o?.assetCode === assetCode)

      if (returnOption) return returnOption

      // @ts-expect-error TS2339,TS7006 (typescriptify)
      return activeOptions.find(o => o?.assetCode === assetCode) || {}
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [availableAssignToOptions],
  )

  // filterOptions only occur based on user input.
  const filteredOptions = useMemo(() => {
    return Object.keys(availableAssignToOptions).reduce((visibleOptions, groupName) => {
      const options = availableAssignToOptions[groupName]

      // @ts-expect-error TS7053 (typescriptify)
      visibleOptions[groupName] = options
        .filter(
          // @ts-expect-error TS7006 (typescriptify)
          option =>
            !currentFilterInput ||
            option.label.toLowerCase().includes(currentFilterInput.toLowerCase()),
        )
        // @ts-expect-error TS7006 (typescriptify)
        .map(option => addIconToOption(option, selectedOptionAssetCode.includes(option.assetCode)))

      return visibleOptions
    }, {})
  }, [currentFilterInput, availableAssignToOptions, selectedOptionAssetCode])

  // For screen-reader users, we want to announce when the available options change
  useEffect(() => {
    setAnnouncement(
      // @ts-expect-error TS2345 (typescriptify)
      `${currentFilterInput}. ${I18n.t('%{optionCount} options available.', {
        // @ts-expect-error TS2339 (typescriptify)
        optionCount: filteredOptions.length,
      })}`,
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filteredOptions])

  const getDefaultHighlightedOption = () => {
    const defaultOptions = Object.values(filteredOptions).flat()
    // @ts-expect-error TS2571 (typescriptify)
    return defaultOptions.length > 0 ? defaultOptions[0].assetCode : null
  }

  // Highlight the default item
  useEffect(() => {
    setHighlightedOptionAssetCode(getDefaultHighlightedOption())

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentFilterInput, filteredOptions])

  useEffect(() => {
    const refObject = {
      assignedToRef: null,
      dueAtRef: null,
      unlockAtRef: null,
    }

    gradedDiscussionRefMap.set(dueDateId, refObject)
    // @ts-expect-error TS2554 (typescriptify)
    setGradedDiscussionRefMap(gradedDiscussionRefMap)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // @ts-expect-error TS7006 (typescriptify)
  const setRefMap = (field, ref) => {
    const refMap = gradedDiscussionRefMap.get(dueDateId)
    refMap[field] = ref
    // @ts-expect-error TS2554 (typescriptify)
    setGradedDiscussionRefMap(new Map(gradedDiscussionRefMap))
  }

  const validateAssignTo = () => {
    const error = []
    const missingAssignToOptionError = {
      text: I18n.t('Please select at least one option.'),
      type: 'error',
    }
    const illegalGroupCategoryError = {
      text: I18n.t('Groups can only be part of the actively selected group set.'),
      type: 'error',
    }
    if (selectedOptionAssetCode.length === 0) {
      error.push(missingAssignToOptionError)
    }

    // @ts-expect-error TS2339 (typescriptify)
    const availableAssetCodes = groups?.map(group => `group_${group._id}`) || []

    if (
      // @ts-expect-error TS7006 (typescriptify)
      selectedOptionAssetCode.filter(assetCode => {
        if (assetCode.includes('group')) {
          return !availableAssetCodes.includes(assetCode)
        } else {
          return false
        }
      }).length > 0
    ) {
      error.push(illegalGroupCategoryError)
    }

    if (error.length > 0) {
      setRefMap('assignedToRef', inputRef)
    } else {
      setRefMap('assignedToRef', null)
    }

    // @ts-expect-error TS2345 (typescriptify)
    setErrorMessage(error)
  }

  useEffect(() => {
    validateAssignTo()
    // @ts-expect-error TS7006 (typescriptify)
    setActiveOptions(selectedOptionAssetCode.map(assetCode => getOptionByAssetCode(assetCode)))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedOptionAssetCode, groupCategoryId])

  // Might rely on id
  // @ts-expect-error TS7006 (typescriptify)
  const handleOptionSelected = assetCode => {
    // @ts-expect-error TS7006 (typescriptify)
    setSelectedOptionAssetCode(prev => [...prev, assetCode])
    onOptionSelect(assetCode) // Notify parent
  }

  const handleBlur = () => {
    setHighlightedOptionAssetCode(null)
  }

  // Don't highlight groups
  // @ts-expect-error TS7006,TS7031 (typescriptify)
  const handleHighlightOption = (event, {id: assetCode}) => {
    event.persist()
    const option = getOptionByAssetCode(assetCode)
    if (!option) return
    setHighlightedOptionAssetCode(assetCode)
    if (!selectedOptionAssetCode.includes(assetCode)) setInputValue(option.label)

    // Announce the option that is highlighted
    setAnnouncement(option.label)
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
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
    // @ts-expect-error TS2345 (typescriptify)
    setAnnouncement(I18n.t('%{optionName} selected. List collapsed.', {optionName: option.label}))
  }

  // Changes that occur when the user types in the input
  // @ts-expect-error TS7006 (typescriptify)
  const handleInputChange = event => {
    const value = event.target.value
    // Any time input is typed, the filter should change
    setCurrentFilterInput(value)
    setInputValue(value)
    setIsShowingOptions(true)
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const dismissTag = (e, tagAssetCode) => {
    e.stopPropagation()
    e.preventDefault()
    const optionBeingRemoved = getOptionByAssetCode(tagAssetCode)
    // @ts-expect-error TS7006 (typescriptify)
    const newSelection = selectedOptionAssetCode.filter(assetCode => assetCode !== tagAssetCode)
    setSelectedOptionAssetCode(newSelection)
    setHighlightedOptionAssetCode(null)
    onOptionDismiss(tagAssetCode) // Notify parent
    setAnnouncement(
      // @ts-expect-error TS2345 (typescriptify)
      I18n.t('%{optionName} selection has been removed', {optionName: optionBeingRemoved.label}),
    )
    // @ts-expect-error TS18047 (typescriptify)
    inputRef.current.focus()
  }

  // @ts-expect-error TS7006 (typescriptify)
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
      // @ts-expect-error TS7006 (typescriptify)
      setSelectedOptionAssetCode(prevSelectedOptionId => prevSelectedOptionId.slice(0, -1))
      onOptionDismiss(lastSelectedTagAssetCode)
      setAnnouncement(
        // @ts-expect-error TS2345 (typescriptify)
        I18n.t('%{optionName} selection has been removed', {optionName: optionBeingRemoved.label}),
      )
    }
  }

  const renderTags = () => {
    // @ts-expect-error TS7006 (typescriptify)
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
      // @ts-expect-error TS7053 (typescriptify)
      if (!filteredOptions[key]?.length) return null
      return (
        <Select.Group key={key} renderLabel={key}>
          {/* @ts-expect-error TS7006,TS7053 (typescriptify) */}
          {filteredOptions[key].map(option => {
            return (
              <Select.Option
                id={option.assetCode}
                key={option.assetCode}
                isHighlighted={option.assetCode === highlightedOptionAssetCode}
                data-testid="assign-to-select-option"
                renderBeforeLabel={option.renderBeforeLabel}
              >
                {option.label}
              </Select.Option>
            )
          })}
        </Select.Group>
      )
    })
  }

  return (
    <View as="span" data-testid="assign-to-select-span">
      {/* @ts-expect-error TS2769 (typescriptify) */}
      <Select
        renderLabel={I18n.t('Assign To')}
        assistiveText={I18n.t(
          'Type or use arrow keys to navigate options. Multiple selections allowed.',
        )}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        inputRef={ref => {
          // @ts-expect-error TS2322 (typescriptify)
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
    </View>
  )
}

AssignedTo.propTypes = {
  dueDateId: PropTypes.string,
  initialAssignedToInformation: PropTypes.arrayOf(PropTypes.string),
  onOptionSelect: PropTypes.func,
  availableAssignToOptions: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        assetCode: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
      }),
    ),
  ).isRequired,
  onOptionDismiss: PropTypes.func,
}

AssignedTo.defaultProps = {
  initialAssignedToInformation: [],
  availableAssignToOptions: {
    'Master Paths': [],
    'Course Sections': [],
    Students: [],
  },
  onOptionSelect: () => {},
  onOptionDismiss: () => {},
}
