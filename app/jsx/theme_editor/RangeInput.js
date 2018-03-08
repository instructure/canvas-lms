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

import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'

var RangeInput = React.createClass({
  propTypes: {
    min: PropTypes.number.isRequired,
    max: PropTypes.number.isRequired,
    defaultValue: PropTypes.number.isRequired,
    labelText: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    step: PropTypes.number,
    formatValue: PropTypes.func,
    onChange: PropTypes.func
  },

  getDefaultProps: function() {
    return {
      step: 1,
      onChange: function() {},
      formatValue: val => val
    }
  },

  getInitialState: function() {
    return {value: this.props.defaultValue}
  },

  /* workaround for https://github.com/facebook/react/issues/554 */
  componentDidMount: function() {
    // https://connect.microsoft.com/IE/Feedback/Details/856998
    $(this.refs.rangeInput.getDOMNode()).on('input change', this.handleChange)
  },

  componentWillUnmount: function() {
    $(this.refs.rangeInput.getDOMNode()).off('input change', this.handleChange)
  },
  /* end workaround */

  handleChange: function(event) {
    this.setState({value: event.target.value})
    this.props.onChange(event.target.value)
  },

  render: function() {
    var {labelText, formatValue, onChange, value, ...props} = this.props

    return (
      <label className="RangeInput">
        <div className="RangeInput__label">{labelText}</div>
        <div className="RangeInput__control">
          <input
            className="RangeInput__input"
            ref="rangeInput"
            type="range"
            role="slider"
            aria-valuenow={this.props.defaultValue}
            aria-valuemin={this.props.min}
            aria-valuemax={this.props.max}
            aria-valuetext={formatValue(this.state.value)}
            onChange={function() {}}
            {...props}
          />
          <output htmlFor={this.props.name} className="RangeInput__value">
            {formatValue(this.state.value)}
          </output>
        </div>
      </label>
    )
  }
})
export default RangeInput
