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
import PropTypes from 'prop-types'
import htmlEscape from 'str/htmlEscape'

export default class Lti2Edit extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    handleActivateLti2: PropTypes.func.isRequired,
    handleDeactivateLti2: PropTypes.func.isRequired,
    handleCancel: PropTypes.func.isRequired
  }

  toggleButton = () => {
    if (this.props.tool.enabled === false) {
      return (
        <button type="button" className="btn btn-primary" onClick={this.props.handleActivateLti2}>
          {I18n.t('Enable')}
        </button>
      )
    } else {
      return (
        <button type="button" className="btn btn-primary" onClick={this.props.handleDeactivateLti2}>
          {I18n.t('Disable')}
        </button>
      )
    }
  }

  render() {
    const p1 = I18n.t('*name* is currently **status**.', {
      wrappers: [
        `<strong>${htmlEscape(this.props.tool.name)}</strong>`,
        this.props.tool.enabled === false ? 'disabled' : 'enabled'
      ]
    })
    return (
      <div className="Lti2Permissions">
        <div className="ReactModal__Body">
          <p dangerouslySetInnerHTML={{__html: p1}} />
        </div>
        <div className="ReactModal__Footer">
          <div className="ReactModal__Footer-Actions">
            {this.toggleButton()}
            <button type="button" className="Button" onClick={this.props.handleCancel}>
              {I18n.t('Cancel')}
            </button>
          </div>
        </div>
      </div>
    )
  }
}
