/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import React, {useState, useEffect} from 'react'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'
import {CloseButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('conversations_2')

export const ALL_COURSES_ID = 'all_courses'

// @ts-expect-error TS7006 (typescriptify)
const filterOptions = (value, options) => {
  const filteredOptions = {}
  Object.keys(options).forEach(key => {
    if (key === 'allCourses') {
      // if provided, allCourses should always be present
      // @ts-expect-error TS7053 (typescriptify)
      filteredOptions[key] = options[key]
    } else {
      // @ts-expect-error TS7053 (typescriptify)
      filteredOptions[key] = options[key]?.filter(
        // @ts-expect-error TS7006 (typescriptify)
        option =>
          option.contextName.toLowerCase().includes(value.toLowerCase()) ||
          option.courseNickname?.toLowerCase().includes(value.toLowerCase()),
      )
    }
  })
  return filteredOptions
}

// @ts-expect-error TS7006 (typescriptify)
const getOptionById = (id, options) => {
  return (
    Object.values(options)
      .flat()
      // @ts-expect-error TS2339 (typescriptify)
      .find(o => o?.assetString === id)
  )
}

// @ts-expect-error TS7006 (typescriptify)
const getCourseName = (courseAssetString, options) => {
  if (courseAssetString) {
    const courseInfo = getOptionById(courseAssetString, options)
    // @ts-expect-error TS2339 (typescriptify)
    return courseInfo ? courseInfo.contextName : ''
  } else {
    return ''
  }
}

// @ts-expect-error TS7006 (typescriptify)
const CourseSelect = props => {
  const [inputValue, setInputValue] = useState(
    props.activeCourseFilterID
      ? getCourseName(props.activeCourseFilterID, props.options)
      : props.mainPage
        ? I18n.t('All Courses')
        : '',
  )
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [filteredOptions, setFilteredOptions] = useState(
    // If there's an active filter, filter by that course name
    // Otherwise, show all options (don't filter by "All Courses" placeholder)
    props.activeCourseFilterID
      ? filterOptions(getCourseName(props.activeCourseFilterID, props.options), props.options)
      : props.options,
  )
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [selectedOptionId, setSelectedOptionId] = useState(
    props.activeCourseFilterID ? props.activeCourseFilterID : null,
  )
  const [isTyping, setIsTyping] = useState(false)

  // Helper function to get the correct input value based on selection state
  // @ts-expect-error TS7006 (typescriptify)
  const getInputValueForSelection = selectedId => {
    if (selectedId) {
      return getCourseName(selectedId, props.options)
    }
    return props.mainPage ? I18n.t('All Courses') : ''
  }

  useEffect(() => {
    if (props.options !== filteredOptions) {
      // Only update input value if user is not actively interacting with the dropdown
      // Prevents unwanted resets while typing or when dropdown is open
      if (!isTyping && !isShowingOptions) {
        setInputValue(
          props.activeCourseFilterID
            ? getCourseName(props.activeCourseFilterID, props.options)
            : getInputValueForSelection(null),
        )
      }
      // Update filtered options when props.options change (but no active filter)
      if (!props.activeCourseFilterID) {
        setFilteredOptions(props.options)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.options, selectedOptionId])

  const getDefaultHighlightedOption = (newOptions = []) => {
    const defaultOptions = Object.values(newOptions).flat()
    // @ts-expect-error TS2339 (typescriptify)
    return defaultOptions.length > 0 ? defaultOptions[0].assetString : null
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
    // Don't restore input value if user is still interacting with dropdown
    if (isTyping || isShowingOptions) {
      return
    }
    setIsTyping(false)
    setInputValue(getInputValueForSelection(selectedOptionId))
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  const handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = getOptionById(id, props.options)
    if (!option) return // prevent highlighting of empty options
    setHighlightedOptionId(id)
    const isArrowKey =
      event.type === 'keydown' && (event.key === 'ArrowUp' || event.key === 'ArrowDown')
    // Update input value during arrow key navigation for autocomplete
    // BUT don't interfere when user is typing
    if (isArrowKey && !isTyping) {
      // @ts-expect-error TS2339 (typescriptify)
      setInputValue(option.contextName)
    }
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  const handleSelectOption = (_event, {id}) => {
    const option = getOptionById(id, props.options)
    if (!option) return // prevent selecting of empty options

    // @ts-expect-error TS2339 (typescriptify)
    const contextName = option.contextName
    const actualId = id === 'all_courses' ? null : id

    props.onCourseFilterSelect({contextID: actualId, contextName})
    setSelectedOptionId(actualId)
    setIsTyping(false)
    setInputValue(getInputValueForSelection(actualId))
    setIsShowingOptions(false)
    setFilteredOptions(props.options)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const handleInputChange = event => {
    const value = event.target.value
    // Filter when user types anything (empty string shows all)
    const newOptions = value !== '' ? filterOptions(value, props.options) : props.options
    setIsTyping(true)
    setInputValue(value)
    setFilteredOptions(newOptions)
    setHighlightedOptionId(getDefaultHighlightedOption(newOptions))
    setIsShowingOptions(true)
    if (value === '') {
      props.onCourseFilterSelect({contextID: null, contextName: null})
      setSelectedOptionId(null)
    }
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
    setFilteredOptions(props.options)
    setHighlightedOptionId(getDefaultHighlightedOption(props.options))
    // Clear "All Courses" text when opening to allow immediate typing
    // Only clear if showing default text and no course is selected
    const isShowingDefaultText = inputValue === I18n.t('All Courses')
    if (!isTyping && props.mainPage && isShowingDefaultText && !selectedOptionId) {
      setInputValue('')
    }
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setIsTyping(false)
    // Restore the previous selection state when dropdown closes (e.g., ESC key, blur)
    setInputValue(getInputValueForSelection(selectedOptionId))
    setFilteredOptions(props.options)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const getGroupLabel = groupKey => {
    switch (groupKey) {
      case 'favoriteCourses':
        return I18n.t('Favorite Courses')
      case 'moreCourses':
        return I18n.t('More Courses')
      case 'concludedCourses':
        return I18n.t('Concluded Courses')
      case 'groups':
        return I18n.t('Groups')
      case 'allCourses':
        return I18n.t('Courses')
    }
  }

  const renderGroups = () => {
    return Object.keys(filteredOptions).map(key => {
      return filteredOptions[key]?.length > 0 ? (
        <Select.Group key={key} renderLabel={getGroupLabel(key)}>
          {/* @ts-expect-error TS7006 (typescriptify) */}
          {filteredOptions[key].map(option => (
            <Select.Option
              id={option.assetString}
              key={option.assetString}
              isHighlighted={option.assetString === highlightedOptionId}
              isSelected={option.assetString === selectedOptionId}
            >
              {option.courseNickname || option.contextName}
              <ScreenReaderContent>
                {I18n.t(` in %{listHeading}`, {listHeading: getGroupLabel(key)})}
              </ScreenReaderContent>
            </Select.Option>
          ))}
        </Select.Group>
      ) : null
    })
  }

  const handleReset = () => {
    props.onCourseFilterSelect({contextID: null, contextName: null})
    setIsTyping(false)
    setInputValue(getInputValueForSelection(null))
    setIsShowingOptions(false)
    setFilteredOptions(props.options)
    setHighlightedOptionId(null)
    setSelectedOptionId(null)
  }

  return (
    // @ts-expect-error TS2769 (typescriptify)
    <Select
      renderLabel={
        <ScreenReaderContent>
          {!props.mainPage && I18n.t('Select course')}
          {props.mainPage && inputValue === '' && I18n.t('Filter messages by course')}
        </ScreenReaderContent>
      }
      assistiveText={I18n.t('Type or use arrow keys to navigate options')}
      placeholder={props.mainPage ? I18n.t('All Courses') : I18n.t('Select Course')}
      inputValue={inputValue}
      isShowingOptions={isShowingOptions}
      onBlur={handleBlur}
      onInputChange={handleInputChange}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={handleHideOptions}
      onRequestHighlightOption={handleHighlightOption}
      onRequestSelectOption={handleSelectOption}
      renderAfterInput={
        selectedOptionId !== null ? (
          <>
            {props.mainPage && (
              <ScreenReaderContent>
                {I18n.t('Filtered by %{courseName}', {
                  courseName: getCourseName(selectedOptionId, props.options),
                })}
              </ScreenReaderContent>
            )}
            <CloseButton
              offset="small"
              data-testid="delete-course-button"
              screenReaderLabel={I18n.t('Clear Course Selection')}
              onClick={handleReset}
            />
          </>
        ) : null
      }
      messages={props.courseMessages}
      data-testid={props.mainPage ? 'course-select' : 'course-select-modal'}
    >
      {renderGroups()}
    </Select>
  )
}

CourseSelect.propTypes = {
  mainPage: PropTypes.bool.isRequired,
  options: PropTypes.shape({
    allCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.oneOf([ALL_COURSES_ID]).isRequired,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      }),
    ),
    favoriteCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      }),
    ),
    moreCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      }),
    ),
    concludedCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      }),
    ),
    groups: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      }),
    ),
  }).isRequired,
  onCourseFilterSelect: PropTypes.func,
  activeCourseFilterID: PropTypes.string,
  courseMessages: PropTypes.array,
}

export default CourseSelect
