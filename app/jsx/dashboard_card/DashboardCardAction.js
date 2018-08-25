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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!dashcards'
import classnames from 'classnames'
import IconAnnouncement from '@instructure/ui-icons/lib/Line/IconAnnouncement'
import IconAssignment from '@instructure/ui-icons/lib/Line/IconAssignment'
import IconDiscussion from '@instructure/ui-icons/lib/Line/IconDiscussion'
import IconFolder from '@instructure/ui-icons/lib/Line/IconFolder'

  var DashboardCardAction = React.createClass({
    displayName: 'DashboardCardAction',

    propTypes: {
      unreadCount: PropTypes.number,
      iconClass: PropTypes.string,
      linkClass: PropTypes.string,
      path: PropTypes.string,
      screenReaderLabel: PropTypes.string
    },

    getDefaultProps: function() {
      return {
        unreadCount: 0
      }
    },

    unreadCountLimiter: function() {
      var count = this.props.unreadCount
      count = (count < 100) ? count : '99+'
      return (
        <span className="unread_count">{count}</span>
      )
    },

    renderIcon: function(iconClass) {
      switch (iconClass) {
        case 'icon-announcement':
          return <IconAnnouncement/>
        case 'icon-assignment':
          return <IconAssignment/>
        case 'icon-discussion':
          return <IconDiscussion/>
        case 'icon-folder':
          return <IconFolder/>
        default:
          // fallback in case I missed one of the icons
          return <i className={iconClass}/>
      }
    },

    render: function () {
      return (
        <a href={this.props.path} className={classnames('ic-DashboardCard__action', this.props.linkClass)}
           title={this.props.screenReaderLabel}>
          { this.props.screenReaderLabel ? (
            <span className="screenreader-only">{
              this.props.screenReaderLabel
            }</span>
            ) : null
          }

          <div className="ic-DashboardCard__action-layout">
            {this.renderIcon(this.props.iconClass)}
            {
              (this.props.unreadCount > 0) ? (
                <span className="ic-DashboardCard__action-badge">
                  { this.unreadCountLimiter() }
                  <span className="screenreader-only">{
                    I18n.t("Unread")
                  }</span>
                </span>
              ) : null
            }
          </div>
        </a>
      );
    }
  });

export default DashboardCardAction
