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

import I18n from 'i18n!new_nav'
import React from 'react'
import PropTypes from 'prop-types'
import SVGWrapper from 'jsx/shared/SVGWrapper'
import PreventDefault from 'compiled/fn/preventDefault'

function readCookie(key) {
  return (document.cookie.match('(^|; )' + encodeURIComponent(key) + '=([^;]*)') || 0)[2]
}

  var ProfileTray = React.createClass({

    propTypes: {
      closeTray: PropTypes.func.isRequired,
      userDisplayName: PropTypes.string.isRequired,
      userAvatarURL: PropTypes.string.isRequired,
      profileEnabled: PropTypes.bool.isRequired,
      eportfoliosEnabled: PropTypes.bool.isRequired
    },

    render() {
      return (
        <div className='profile-tray'>
          <div className="ic-NavMenu__header ic-NavMenu__header--is-profile" id="global_nav_profile_header">
            <div className="ic-NavMenu-profile-header-close">
              <button
                className="Button Button--icon-action ic-NavMenu__closeButton"
                type="button" onClick={this.props.closeTray}>
                <i className="icon-x" aria-hidden="true"></i>
                <span className="screenreader-only">{I18n.t('Close')}</span>
              </button>
            </div>
            <div className="ic-avatar">
              <img
                src={this.props.userAvatarURL}
                alt={I18n.t('User profile picture')}
                className="ic-NavMenu-profile-header-avatar-image"
              />
            </div>
            <h1
              className="ic-NavMenu__headline ellipsis"
              id="global_nav_profile_display_name"
              title={this.props.userDisplayName}
            >
                {this.props.userDisplayName}
            </h1>
            <form
              ref="logoutForm"
              action="/logout"
              method="post"
              className="ic-NavMenu-profile-header-logout-form"
            >
              <input name="utf8" value="✓" type="hidden"/>
              <input name="_method" value="delete" type="hidden"/>
              <input name="authenticity_token" value={readCookie('_csrf_token')} type="hidden"/>
              <button
                type="submit"
                className="Button Button--small">
                {I18n.t('Logout')}
              </button>
            </form>
          </div>
          <ul className="ic-NavMenu__link-list">
            {this.props.profileEnabled &&
              <li className="ic-NavMenu-list-item">
                <a href="/profile" className="ic-NavMenu-list-item__link">{I18n.t('Profile')}</a>
              </li>
            }
            <li className="ic-NavMenu-list-item">
              <a href="/profile/settings" className="ic-NavMenu-list-item__link">{I18n.t('Settings')}</a>
            </li>
            <li className="ic-NavMenu-list-item">
              <a href="/profile/communication" className="ic-NavMenu-list-item__link">{I18n.t('Notifications')}</a>
            </li>
            <li className="ic-NavMenu-list-item">
              <a href="/files" className="ic-NavMenu-list-item__link">{I18n.t('Files')}</a>
            </li>
            {this.props.eportfoliosEnabled &&
              <li className="ic-NavMenu-list-item">
                <a href="/dashboard/eportfolios" className="ic-NavMenu-list-item__link">{I18n.t('ePortfolios')}</a>
              </li>
            }
          </ul>
        </div>
      );
    }
  });

export default ProfileTray
