/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {Component} from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'

export default class RangeInput extends Component {
  static propTypes = {
    min: PropTypes.number.isRequired,
    max: PropTypes.number.isRequired,
    defaultValue: PropTypes.number.isRequired,
    labelText: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    step: PropTypes.number,
    formatValue: PropTypes.func,
    onChange: PropTypes.func,
    themeState: PropTypes.object,
    handleThemeStateChange: PropTypes.func,
    variableKey: PropTypes.string.isRequired
  }

  static defaultProps = {
    step: 1,
    onChange() {},
    formatValue: val => val,
    themeState: {},
    handleThemeStateChange() {}
  }

  state = {
    value: this.props.defaultValue
  }

  /* TODO: Remove this workaround when we upgrade to 15.6.x or later */
  /* workaround for https://github.com/facebook/react/issues/554 */
  componentDidMount() {
    // https://connect.microsoft.com/IE/Feedback/Details/856998
    $(this.rangeInput).on('input change', this.handleChange)
  }

  componentWillUnmount() {
    $(this.rangeInput).off('input change', this.handleChange)
  }
  /* end workaround */

  handleChange = event => {
    this.setState({value: event.target.value})
    this.props.onChange(event.target.value)
    this.props.handleThemeStateChange(this.props.variableKey, event.target.value)
  }

  render() {
    var {labelText, formatValue, onChange, value, ...props} = this.props

    return (
      <label className="RangeInput">
        <div className="RangeInput__label">{labelText}</div>
        <div className="RangeInput__control">
          <input
            className="RangeInput__input"
            ref={c => (this.rangeInput = c)}
            type="range"
            role="slider"
            aria-valuenow={this.props.defaultValue}
            aria-valuemin={this.props.min}
            aria-valuemax={this.props.max}
            aria-valuetext={formatValue(this.state.value)}
            onChange={() => {}}
            {...props}
          />
          <output
            ref={c => (this.outputElement = c)}
            htmlFor={this.props.name}
            className="RangeInput__value"
          >
            {formatValue(this.state.value)}
          </output>
        </div>
      </label>
    )
  }
}
