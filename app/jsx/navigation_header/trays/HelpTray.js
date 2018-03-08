/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!new_nav'
import React from 'react'
import PropTypes from 'prop-types'
import HelpDialog from '../../help_dialog/HelpDialog'

var HelpTray = React.createClass({
  propTypes: {
    trayTitle: PropTypes.string,
    closeTray: PropTypes.func.isRequired,
    links: PropTypes.array,
    hasLoaded: PropTypes.bool
  },

  getDefaultProps() {
    return {
      trayTitle: I18n.t('Help'),
      hasLoaded: false,
      links: []
    }
  },

  render() {
    return (
      <div id="help_tray">
        <div className="ic-NavMenu__header">
          <h1 className="ic-NavMenu__headline">{this.props.trayTitle}</h1>
          <button
            className="Button Button--icon-action ic-NavMenu__closeButton"
            type="button"
            onClick={this.props.closeTray}
          >
            <i className="icon-x" aria-hidden="true" />
            <span className="screenreader-only">{I18n.t('Close')}</span>
          </button>
        </div>
        <HelpDialog
          links={this.props.links}
          hasLoaded={this.props.hasLoaded}
          onFormSubmit={this.props.closeTray}
        />
      </div>
    )
  }
})

export default HelpTray
