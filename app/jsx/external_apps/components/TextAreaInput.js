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

import I18n from 'i18n!external_tools'
import $ from 'jquery'
import React from 'react'
import InputMixin from 'jsx/external_apps/mixins/InputMixin'

export default React.createClass({
    displayName: 'TextAreaInput',

    mixins: [InputMixin],

    propTypes: {
      defaultValue: React.PropTypes.string,
      label:        React.PropTypes.string,
      id:           React.PropTypes.string,
      rows:         React.PropTypes.number,
      required:     React.PropTypes.bool,
      hintText:     React.PropTypes.string,
      errors:       React.PropTypes.object
    },

    render() {
      return (
        <div className={this.getClassNames()}>
          <label>
            {this.props.label}
            <textarea ref="input" rows={this.props.rows || 3} defaultValue={this.props.defaultValue}
              className="form-control input-block-level"
              placeholder={this.props.label} id={this.props.id}
              required={this.props.required ? "required" : null}
              onChange={this.handleChange}
              aria-invalid={!!this.getErrorMessage()} />
            {this.renderHint()}
          </label>
        </div>
      )
    }
  });
