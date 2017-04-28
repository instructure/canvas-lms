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

export default React.createClass({
    displayName: 'Lti2Iframe',

    propTypes: {
      reregistration: React.PropTypes.bool,
      registrationUrl: React.PropTypes.string.isRequired,
      handleInstall: React.PropTypes.func.isRequired
    },

    componentDidMount() {
      window.addEventListener('message', function(e) {
        var message = e.data;
        if (typeof message !== 'object') {
          message = JSON.parse(e.data);
        }
        if (message.subject === 'lti.lti2Registration') {
          this.props.handleInstall(message, e);
        }
      }.bind(this), false);
    },

    getLaunchUrl() {
      if (this.props.reregistration) {
        return this.props.registrationUrl
      }
      else {
        return ENV.LTI_LAUNCH_URL + '?display=borderless&tool_consumer_url=' + this.props.registrationUrl;
      }
    },

    render() {
      return (
        <div>
          <div className="ReactModal__Body" style={{padding: '0px !important'}}>
            <iframe src={this.getLaunchUrl()} className="tool_launch" title={ I18n.t('Tool Content')} />
          </div>
         {this.props.children}
        </div>
      )
    }
  });
