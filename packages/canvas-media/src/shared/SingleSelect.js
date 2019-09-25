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
import {arrayOf, element, func, shape, string} from 'prop-types'
import React from 'react'

import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'

// TODO:
//   - i18n this file and figure out how to i18n strings with variables without
//     access to i18n proper.

export default class SingleSelect extends React.Component {
  state = {
    inputValue: this.props.options[0].label,
    isShowingOptions: false,
    highlightedOptionId: null,
    selectedOptionId: this.props.options[0].id,
    announcement: null
  }

  static propTypes = {
    liveRegion: func,
    options: arrayOf(
      shape({
        id: string,
        label: string
      })
    ),
    renderLabel: element,
    selectedOption: func
  }

  getOptionById(queryId) {
    return this.props.options.find(({id}) => id === queryId)
  }

  handleShowOptions = () => {
    this.setState({
      isShowingOptions: true
    })
  }

  handleHideOptions = () => {
    const {selectedOptionId} = this.state
    const option = this.getOptionById(selectedOptionId).label
    this.setState({
      isShowingOptions: false,
      highlightedOptionId: null,
      inputValue: selectedOptionId ? option : '',
      announcement: 'List collapsed.'
    })
  }

  handleBlur = () => {
    this.setState({highlightedOptionId: null})
  }

  handleHighlightOption = (event, {id}) => {
    event.persist()
    const optionsAvailable = `${this.props.options.length} options available.`
    const nowOpen = !this.state.isShowingOptions ? `List expanded. ${optionsAvailable}` : ''
    const option = this.getOptionById(id).label
    this.setState(state => ({
      highlightedOptionId: id,
      inputValue: event.type === 'keydown' ? option : state.inputValue,
      announcement: `${option} ${nowOpen}`
    }))
  }

  handleSelectOption = (event, {id}) => {
    const option = this.getOptionById(id).label
    this.props.selectedOption({
      selectedOptionId: id,
      inputValue: option
    })
    this.setState({
      selectedOptionId: id,
      inputValue: option,
      isShowingOptions: false,
      announcement: `"${option}" selected. List collapsed.`
    })
  }

  render() {
    const {
      inputValue,
      isShowingOptions,
      highlightedOptionId,
      selectedOptionId,
      announcement
    } = this.state

    return (
      <div>
        <Select
          renderLabel={this.props.renderLabel}
          assistiveText="Use arrow keys to navigate options."
          inputValue={inputValue}
          isShowingOptions={isShowingOptions}
          onBlur={this.handleBlur}
          onRequestShowOptions={this.handleShowOptions}
          onRequestHideOptions={this.handleHideOptions}
          onRequestHighlightOption={this.handleHighlightOption}
          onRequestSelectOption={this.handleSelectOption}
        >
          {this.props.options.map(option => {
            return (
              <Select.Option
                id={option.id}
                key={option.id}
                isHighlighted={option.id === highlightedOptionId}
                isSelected={option.id === selectedOptionId}
              >
                {option.label}
              </Select.Option>
            )
          })}
        </Select>
        {/*
         * This is causing a lot of "Replacing React-rendered children with a new root component"
         * warnings that we should deal with at somepoint.
         */}
        <Alert liveRegion={this.props.liveRegion} liveRegionPoliteness="assertive" screenReaderOnly>
          {announcement}
        </Alert>
      </div>
    )
  }
}
