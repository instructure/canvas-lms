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

import PropTypes from 'prop-types'
import React from 'react'

import {Alert} from '@instructure/ui-alerts'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'
import I18n from 'i18n!conversations_2'

const filterOptions = (value, options) => {
  const filteredOptions = {}
  Object.keys(options).forEach(key => {
    filteredOptions[key] = options[key].filter(option =>
      option.contextName.toLowerCase().startsWith(value.toLowerCase())
    )
  })
  return filteredOptions
}

export class CourseSelect extends React.Component {
  static propTypes = {
    mainPage: PropTypes.bool.isRequired,
    options: PropTypes.shape({
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
    onCourseFilterSelect: PropTypes.func
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
    inputValue: '',
    isShowingOptions: false,
    options: this.props.options,
    filteredOptions: this.props.options,
    highlightedOptionId: null,
    selectedOptionId: null,
    announcement: null
  }

  getDefaultHighlightedOption = (newOptions = []) => {
    const options = Object.values(newOptions).flat()
    return options.length > 0 ? options[0].assetString : null
  }

  getGroupChangedMessage = newOption => {
    const currentOption = this.getOptionById(this.state.highlightedOptionId)
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

  getOptionById = id => {
    return Object.values(this.props.options)
      .flat()
      .find(({assetString}) => id === assetString)
  }

  handleBlur = () => {
    this.setState({highlightedOptionId: null})
  }

  handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = this.getOptionById(id)
    if (!option) return // prevent highlighting of empty options
    this.getGroupChangedMessage(option)
    this.setState(state => ({
      highlightedOptionId: id,
      inputValue: event.type === 'keydown' ? option.contextName : state.inputValue,
      announcement: this.getGroupChangedMessage(option)
    }))
  }

  handleSelectOption = (event, {id}) => {
    const option = this.getOptionById(id)
    const contextName = option.contextName
    if (!option) return // prevent selecting of empty options
    this.props.onCourseFilterSelect(id)
    this.setState({
      selectedOptionId: id,
      inputValue: option.contextName,
      isShowingOptions: false,
      filteredOptions: this.props.options,
      announcement: I18n.t('%{contextName} selected', {contextName})
    })
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

  render() {
    const {inputValue, isShowingOptions, announcement} = this.state
    return (
      <>
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
          data-testid="courseSelect"
        >
          {this.renderGroups()}
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
}
