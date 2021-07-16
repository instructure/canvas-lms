/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!feature_flags'
import React from 'react'

import {Alert} from '@instructure/ui-alerts'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'

export default class FeatureFlagFilter extends React.Component {
  state = {
    inputValue: '',
    isShowingOptions: false,
    highlightedOptionId: null,
    selectedOptionId: [],
    filteredOptions: this.props.options,
    announcement: null
  }

  getOptionById(queryId) {
    return this.props.options.find(({id}) => id === queryId)
  }

  getOptionsChangedMessage(newOptions) {
    let message =
      newOptions.length !== this.state.filteredOptions.length
        ? I18n.t(
            {
              one: 'One option available',
              other: '%{count} options available'
            },
            {count: newOptions.length}
          ) // options changed, announce new total
        : null // options haven't changed, don't announce
    if (message && newOptions.length > 0) {
      // options still available
      if (this.state.highlightedOptionId !== newOptions[0].id) {
        // highlighted option hasn't been announced
        const option = this.getOptionById(newOptions[0].id).label
        message = `${option}. ${message}`
      }
    }
    return message
  }

  filterOptions = value => {
    return this.props.options.filter(option =>
      option.label.toLowerCase().startsWith(value.toLowerCase())
    )
  }

  matchValue() {
    const {filteredOptions, inputValue, highlightedOptionId, selectedOptionId} = this.state

    // an option matching user input exists
    if (filteredOptions.length === 1) {
      const onlyOption = filteredOptions[0]
      // automatically select the matching option
      if (onlyOption.label.toLowerCase() === inputValue.toLowerCase()) {
        return {
          inputValue: '',
          selectedOptionId: [...selectedOptionId, onlyOption.id],
          filteredOptions: this.filterOptions('')
        }
      }
    }
    // input value is from highlighted option, not user input
    // clear input, reset options
    if (highlightedOptionId) {
      if (inputValue === this.getOptionById(highlightedOptionId).label) {
        return {
          inputValue: '',
          filteredOptions: this.filterOptions('')
        }
      }
    }
  }

  handleShowOptions = _event => {
    this.setState({isShowingOptions: true})
  }

  handleHideOptions = _event => {
    this.setState({
      isShowingOptions: false,
      ...this.matchValue()
    })
  }

  handleBlur = _event => {
    this.setState({
      highlightedOptionId: null
    })
  }

  handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = this.getOptionById(id)
    if (!option) return // prevent highlighting empty option
    this.setState(state => ({
      highlightedOptionId: id,
      inputValue: event.type === 'keydown' ? option.label : state.inputValue,
      announcement: option.label
    }))
  }

  handleSelectOption = (_event, {id}) => {
    const option = this.getOptionById(id)
    if (!option) return // prevent selecting of empty option
    this.setState(state => ({
      selectedOptionId: [...state.selectedOptionId, id],
      highlightedOptionId: null,
      filteredOptions: this.filterOptions(''),
      inputValue: '',
      isShowingOptions: false,
      announcement: I18n.t('%{label} selected. List collapsed.', {label: option.label})
    }))
    this.props.onChange([...this.state.selectedOptionId, id])
  }

  handleInputChange = event => {
    const value = event.target.value
    const newOptions = this.filterOptions(value)
    this.setState({
      inputValue: value,
      filteredOptions: newOptions,
      highlightedOptionId: newOptions.length > 0 ? newOptions[0].id : null,
      isShowingOptions: true,
      announcement: this.getOptionsChangedMessage(newOptions)
    })
  }

  handleKeyDown = event => {
    const {selectedOptionId, inputValue} = this.state
    if (event.keyCode === 8) {
      // when backspace key is pressed
      if (inputValue === '' && selectedOptionId.length > 0) {
        // remove last selected option, if input has no entered text
        this.setState(state => ({
          highlightedOptionId: null,
          selectedOptionId: state.selectedOptionId.slice(0, -1)
        }))
        this.props.onChange(selectedOptionId.slice(0, -1))
      }
    }
  }

  // remove a selected option tag
  dismissTag(e, tag) {
    // prevent closing of list
    e.stopPropagation()
    e.preventDefault()

    this.setState(
      ({selectedOptionId}) => ({
        selectedOptionId: selectedOptionId.filter(id => id !== tag),
        highlightedOptionId: null
      }),
      () => {
        this.inputRef.focus()
        this.props.onChange(this.state.selectedOptionId)
      }
    )
  }

  // render tags when multiple options are selected
  renderTags() {
    const {selectedOptionId} = this.state
    return selectedOptionId.map((id, index) => (
      <Tag
        dismissible
        key={id}
        title={I18n.t('Remove %{label}', {label: this.getOptionById(id).label})}
        text={this.getOptionById(id).label}
        margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
        onClick={e => this.dismissTag(e, id)}
      />
    ))
  }

  render() {
    const {
      inputValue,
      isShowingOptions,
      highlightedOptionId,
      selectedOptionId,
      filteredOptions,
      announcement
    } = this.state

    return (
      <div>
        <Select
          renderLabel={<ScreenReaderContent>{I18n.t('Filter Features')}</ScreenReaderContent>}
          placeholder={I18n.t('Filter Features')}
          assistiveText={I18n.t(
            'Type or use arrow keys to navigate options. Multiple selections allowed.'
          )}
          inputValue={inputValue}
          isShowingOptions={isShowingOptions}
          inputRef={el => (this.inputRef = el)}
          onBlur={this.handleBlur}
          onInputChange={this.handleInputChange}
          onRequestShowOptions={this.handleShowOptions}
          onRequestHideOptions={this.handleHideOptions}
          onRequestHighlightOption={this.handleHighlightOption}
          onRequestSelectOption={this.handleSelectOption}
          onKeyDown={this.handleKeyDown}
          renderBeforeInput={selectedOptionId.length > 0 ? this.renderTags() : null}
        >
          {filteredOptions.length > 0 ? (
            filteredOptions.map((option, _index) => {
              if (selectedOptionId.indexOf(option.id) === -1) {
                return (
                  <Select.Option
                    id={option.id}
                    key={option.id}
                    isHighlighted={option.id === highlightedOptionId}
                  >
                    {option.label}
                  </Select.Option>
                )
              }
              return null
            })
          ) : (
            <Select.Option id="empty-option" key="empty-option">
              ---
            </Select.Option>
          )}
        </Select>
        <Alert
          liveRegion={() => document.getElementById('aria_alerts')}
          liveRegionPoliteness="assertive"
          screenReaderOnly
        >
          {announcement}
        </Alert>
      </div>
    )
  }
}
