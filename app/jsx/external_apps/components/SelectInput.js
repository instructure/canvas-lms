/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import React from 'react'
import createReactClass from 'create-react-class'
import PropTypes from 'prop-types'
import InputMixin from '../../external_apps/mixins/InputMixin'

export default createReactClass({
  displayName: 'SelectInput',

  mixins: [InputMixin],

  propTypes: {
    defaultValue: PropTypes.string,
    allowBlank: PropTypes.bool,
    values: PropTypes.object,
    label: PropTypes.string,
    id: PropTypes.string,
    required: PropTypes.bool,
    hintText: PropTypes.string,
    errors: PropTypes.object
  },

  renderSelectOptions() {
    const options = _.map(
      this.props.values,
      (v, k) => <option key={k} value={k}>{v}</option>
    )
    if (this.props.allowBlank) {
      options.unshift(<option key="NO_VALUE" value={null} />)
    }
    return options
  },

  handleSelectChange(e) {
    e.preventDefault()
    this.setState({value: e.target.value})
  },

  render() {
    return (
      <div className={this.getClassNames()}>
        <label>
          {this.props.label}
          <select
            ref="input"
            className="form-control input-block-level"
            defaultValue={this.props.defaultValue}
            required={this.props.required ? 'required' : null}
            onChange={this.handleSelectChange}
            aria-invalid={!!this.getErrorMessage()}
          >
            {this.renderSelectOptions()}
          </select>
          {this.renderHint()}
        </label>
      </div>
    )
  }
})
