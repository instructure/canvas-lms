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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useState, useEffect} from 'react'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'
import {CloseButton} from '@instructure/ui-buttons'

const I18n = useI18nScope('conversations_2')

export const ALL_COURSES_ID = 'all_courses'

const filterOptions = (value, options) => {
  const filteredOptions = {}
  Object.keys(options).forEach(key => {
    if (key === 'allCourses') {
      // if provided, allCourses should always be present
      filteredOptions[key] = options[key]
    } else {
      filteredOptions[key] = options[key]?.filter(
        option =>
          option.contextName.toLowerCase().includes(value.toLowerCase()) ||
          option.courseNickname?.toLowerCase().includes(value.toLowerCase())
      )
    }
  })
  return filteredOptions
}

const getOptionById = (id, options) => {
  return Object.values(options)
    .flat()
    .find(o => o?.assetString === id)
}

const getCourseName = (courseAssetString, options) => {
  if (courseAssetString) {
    const courseInfo = getOptionById(courseAssetString, options)
    return courseInfo ? courseInfo.contextName : ''
  } else {
    return ''
  }
}

const CourseSelect = props => {
  const [inputValue, setInputValue] = useState(
    getCourseName(props.activeCourseFilterID, props.options)
  )
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [options, setOptions] = useState(props.options)
  const [filteredOptions, setFilteredOptions] = useState(
    filterOptions(getCourseName(props.activeCourseFilterID, props.options), props.options)
  )
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [selectedOptionId, setSelectedOptionId] = useState(
    props.activeCourseFilterID ? props.activeCourseFilterID : null
  )
  const [autoComplete, setAutoComplete] = useState(false)

  useEffect(() => {
    if (props.options !== filteredOptions) {
      setOptions(filterOptions(inputValue, props.options))
      setInputValue(getCourseName(props.activeCourseFilterID, props.options))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.options, selectedOptionId])

  useEffect(() => {
    if (autoComplete) return
    setOptions(filterOptions(inputValue, props.options))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inputValue, props.options])

  const getDefaultHighlightedOption = (newOptions = []) => {
    const defaultOptions = Object.values(newOptions).flat()
    return defaultOptions.length > 0 ? defaultOptions[0].assetString : null
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
    setAutoComplete(false)
    if (selectedOptionId) {
      setInputValue(getCourseName(selectedOptionId, props.options))
    }
  }

  const handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = getOptionById(id, props.options)
    if (!option) return // prevent highlighting of empty options
    // if event key is arrow up or down, don't update input value
    setHighlightedOptionId(id)
    const autoComp =
      event.type === 'keydown' && (event.key === 'ArrowUp' || event.key === 'ArrowDown')
    setAutoComplete(autoComp)
    setInputValue(autoComp ? option.contextName : inputValue)
  }

  const handleSelectOption = (event, {id}) => {
    const option = getOptionById(id, props.options)
    const contextName = option.contextName
    if (!option) return // prevent selecting of empty options
    if (id === 'all_courses') id = null
    props.onCourseFilterSelect({contextID: id, contextName})
    setSelectedOptionId(id)
    setInputValue(id === null ? '' : option.contextName)
    setIsShowingOptions(false)
    setFilteredOptions(props.options)
  }

  const handleInputChange = event => {
    const value = event.target.value
    const newOptions = filterOptions(value, props.options)
    setAutoComplete(false)
    setInputValue(value)
    setFilteredOptions(newOptions)
    setHighlightedOptionId(getDefaultHighlightedOption(newOptions))
    setIsShowingOptions(true)
    if (value === '') {
      props.onCourseFilterSelect({contextID: null, contextName: null})
      setSelectedOptionId(null)
    } else {
      setSelectedOptionId(selectedOptionId)
    }
  }

  const handleShowOptions = () => {
    if (inputValue !== '') return
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
  }

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
    return Object.keys(options).map(key => {
      return options[key]?.length > 0 ? (
        <Select.Group key={key} renderLabel={getGroupLabel(key)}>
          {options[key].map(option => (
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
    setAutoComplete(false)
    setInputValue('')
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setSelectedOptionId(null)
  }

  return (
    <Select
      renderLabel={
        <ScreenReaderContent>
          {props.mainPage ? I18n.t('Filter messages by course') : I18n.t('Select course')}
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
        inputValue !== '' ? (
          <CloseButton
            offset="small"
            data-testid="delete-course-button"
            screenReaderLabel={I18n.t('Clear Course Selection')}
            onClick={handleReset}
          />
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
      })
    ),
    favoriteCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      })
    ),
    moreCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      })
    ),
    concludedCourses: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      })
    ),
    groups: PropTypes.arrayOf(
      PropTypes.shape({
        _id: PropTypes.string,
        contextName: PropTypes.string,
        assetString: PropTypes.string,
      })
    ),
  }).isRequired,
  onCourseFilterSelect: PropTypes.func,
  activeCourseFilterID: PropTypes.string,
  courseMessages: PropTypes.array,
}

export default CourseSelect
