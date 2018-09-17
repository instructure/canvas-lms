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

import React from 'react'
import createReactClass from 'create-react-class'
import PropTypes from 'prop-types'
import InputMixin from '../../external_apps/mixins/InputMixin'

export default createReactClass({
  displayName: 'TextAreaInput',

  mixins: [InputMixin],

  propTypes: {
    defaultValue: PropTypes.string,
    label: PropTypes.string,
    id: PropTypes.string,
    rows: PropTypes.number,
    required: PropTypes.bool,
    hintText: PropTypes.string,
    errors: PropTypes.object
  },

  render() {
    return (
      <div className={this.getClassNames()}>
        <label>
          {this.props.label}
          <textarea
            ref="input"
            rows={this.props.rows || 3}
            defaultValue={this.props.defaultValue}
            className="form-control input-block-level"
            placeholder={this.props.label}
            id={this.props.id}
            required={this.props.required ? 'required' : null}
            onChange={this.handleChange}
            aria-invalid={!!this.getErrorMessage()}
          />
          {this.renderHint()}
        </label>
      </div>
    )
  }
})
