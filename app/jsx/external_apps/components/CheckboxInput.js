/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import InputMixin from 'jsx/external_apps/mixins/InputMixin'

export default createReactClass({
  displayName: 'CheckboxInput',

  mixins: [InputMixin],

  propTypes: {
    defaultValue: PropTypes.string,
    checked: PropTypes.bool,
    label: PropTypes.string,
    id: PropTypes.string,
    required: PropTypes.bool,
    errors: PropTypes.object,
    name: PropTypes.string
  },

  render() {
    return (
      <div className={`checkbox ${this.getClassNames()}`}>
        <label>
          <input
            type="checkbox"
            ref="input"
            defaultChecked={this.props.checked}
            onChange={this.handleCheckChange}
            aria-invalid={!!this.getErrorMessage()}
            name={this.props.name || null}
          />
          {this.props.label}
        </label>
      </div>
    )
  }
})
