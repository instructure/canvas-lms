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
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import PropTypes from 'prop-types'
import React from 'react'

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
      filteredOptions[key] = options[key]?.filter(option =>
        option.contextName.toLowerCase().startsWith(value.toLowerCase())
      )
    }
  })
  return filteredOptions
}

const getOptionById = (id, options) => {
  return Object.values(options)
    .flat()
    .find(({assetString}) => id === assetString)
}

const getCourseName = (courseAssetString, options) => {
  if (courseAssetString) {
    const courseInfo = getOptionById(courseAssetString, options)
    return courseInfo ? courseInfo.contextName : ''
  } else {
    return ''
  }
}

export class CourseSelect extends React.Component {
  static propTypes = {
    mainPage: PropTypes.bool.isRequired,
    options: PropTypes.shape({
      allCourses: PropTypes.arrayOf(
        PropTypes.shape({
          _id: PropTypes.oneOf([ALL_COURSES_ID]).isRequired,
          contextName: PropTypes.string,
          assetString: PropTypes.string
        })
      ),
      favoriteCourses: PropTypes.arrayOf(
        PropTypes.shape({
          _id: PropTypes.string,
          contextName: PropTypes.string,
          assetString: PropTypes.string
        })
      ),
      moreCourses: PropTypes.arrayOf(
        PropTypes.shape({
          _id: PropTypes.string,
          contextName: PropTypes.string,
          assetString: PropTypes.string
        })
      ),
      concludedCourses: PropTypes.arrayOf(
        PropTypes.shape({
          _id: PropTypes.string,
          contextName: PropTypes.string,
          assetString: PropTypes.string
        })
      ),
      groups: PropTypes.arrayOf(
        PropTypes.shape({
          _id: PropTypes.string,
          contextName: PropTypes.string,
          assetString: PropTypes.string
        })
      )
    }).isRequired,
    onCourseFilterSelect: PropTypes.func,
    activeCourseFilterID: PropTypes.string,
    courseMessages: PropTypes.array
  }

  static getDerivedStateFromProps(props, state) {
    if (props.options !== state.options) {
      return {
        filteredOptions: filterOptions(state.inputValue, props.options)
      }
    }
    return null
  }

  state = {
    inputValue: getCourseName(this.props.activeCourseFilterID, this.props.options),
    isShowingOptions: false,
    options: this.props.options,
    filteredOptions: filterOptions(
      getCourseName(this.props.activeCourseFilterID, this.props.options),
      this.props.options
    ),
    highlightedOptionId: null,
    selectedOptionId: this.props.activeCourseFilterID ? this.props.activeCourseFilterID : null
  }

  getDefaultHighlightedOption = (newOptions = []) => {
    const options = Object.values(newOptions).flat()
    return options.length > 0 ? options[0].assetString : null
  }

  getGroupChangedMessage = newOption => {
    const currentOption = getOptionById(this.state.highlightedOptionId, this.props.options)
    const currentOptionGroup = this.getOptionGroup(currentOption)
    const newOptionGroup = this.getOptionGroup(newOption)

    const isNewGroup = !currentOption || currentOptionGroup !== newOptionGroup
    const newOptionContextName = newOption.contextName
    const message = isNewGroup
      ? I18n.t('Group %{newOptionGroup} entered. %{newOptionContextName}', {
          newOptionContextName,
          newOptionGroup
        })
      : newOption.contextName
    return message
  }

  getOptionGroup = option => {
    if (!option) return
    return this.getGroupLabel(
      Object.keys(this.props.options).find(key =>
        this.props.options[key].find(({assetString}) => assetString === option.assetString)
      )
    )
  }

  handleBlur = () => {
    this.setState({highlightedOptionId: null})
  }

  handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = getOptionById(id, this.props.options)
    if (!option) return // prevent highlighting of empty options
    if (event.key) {
      this.setState({
        highlightedOptionId: id
      })
    } else {
      this.setState(
        state => ({
          highlightedOptionId: id,
          inputValue: state.inputValue
        }),
        () => {
          this.context.setOnSuccess(this.getGroupChangedMessage(option))
        }
      )
    }
  }

  handleSelectOption = (event, {id}) => {
    const option = getOptionById(id, this.props.options)
    const contextName = option.contextName
    if (!option) return // prevent selecting of empty options
    if (id === 'all_courses') id = null
    this.props.onCourseFilterSelect({contextID: id, contextName})
    this.setState(
      {
        selectedOptionId: id,
        inputValue: id === null ? '' : option.contextName,
        isShowingOptions: false,
        filteredOptions: this.props.options
      },
      () => {
        this.context.setOnSuccess(I18n.t('%{contextName} selected', {contextName}))
      }
    )
  }

  handleInputChange = event => {
    const value = event.target.value
    const newOptions = filterOptions(value, this.props.options)
    this.setState(state => ({
      inputValue: value,
      filteredOptions: newOptions,
      highlightedOptionId: this.getDefaultHighlightedOption(newOptions),
      isShowingOptions: true,
      selectedOptionId: value === '' ? null : state.selectedOptionId
    }))
  }

  handleShowOptions = () => {
    if (this.state.inputValue !== '') return

    this.setState({
      isShowingOptions: true
    })
  }

  handleHideOptions = () => {
    this.setState({
      isShowingOptions: false,
      highlightedOptionId: null
    })
  }

  getGroupLabel = groupKey => {
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

  renderGroups = () => {
    const options = this.state.filteredOptions
    const {highlightedOptionId, selectedOptionId} = this.state

    return Object.keys(options).map(key => {
      return options[key]?.length > 0 ? (
        <Select.Group key={key} renderLabel={this.getGroupLabel(key)}>
          {options[key].map(option => (
            <Select.Option
              id={option.assetString}
              key={option.assetString}
              isHighlighted={option.assetString === highlightedOptionId}
              isSelected={option.assetString === selectedOptionId}
            >
              {option.contextName}
            </Select.Option>
          ))}
        </Select.Group>
      ) : null
    })
  }

  handleReset = () => {
    this.props.onCourseFilterSelect({contextID: null, contextName: null})
    this.setState({
      inputValue: '',
      isShowingOptions: false,
      highlightedOptionId: null,
      selectedOptionId: null
    })
  }

  render() {
    const {inputValue, isShowingOptions} = this.state
    return (
      <Select
        renderLabel={
          <ScreenReaderContent>
            {this.props.mainPage ? I18n.t('Filter messages by course') : I18n.t('Select course')}
          </ScreenReaderContent>
        }
        assistiveText={I18n.t('Type or use arrow keys to navigate options')}
        placeholder={this.props.mainPage ? I18n.t('All Courses') : I18n.t('Select Course')}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        onBlur={this.handleBlur}
        onInputChange={this.handleInputChange}
        onRequestShowOptions={this.handleShowOptions}
        onRequestHideOptions={this.handleHideOptions}
        onRequestHighlightOption={this.handleHighlightOption}
        onRequestSelectOption={this.handleSelectOption}
        renderAfterInput={
          inputValue !== '' ? (
            <CloseButton
              offset="small"
              data-testid="delete-course-button"
              screenReaderLabel={I18n.t('Clear Course Selection')}
              onClick={this.handleReset}
            />
          ) : null
        }
        messages={this.props.courseMessages}
        data-testid="course-select"
      >
        {this.renderGroups()}
      </Select>
    )
  }
}

CourseSelect.contextType = AlertManagerContext
