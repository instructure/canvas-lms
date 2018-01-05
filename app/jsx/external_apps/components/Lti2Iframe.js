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
import iframeAllowances from '../lib/iframeAllowances'

export default React.createClass({
  displayName: 'Lti2Iframe',

  propTypes: {
    reregistration: PropTypes.bool,
    registrationUrl: PropTypes.string,
    handleInstall: PropTypes.func.isRequired,
    hideComponent: PropTypes.bool
  },

  getInitialState () {
    return {
      beforeExternalContentAlertClass: 'screenreader-only',
      afterExternalContentAlertClass: 'screenreader-only',
      iframeStyle: {}
    }
  },

  componentDidMount () {
    window.addEventListener('message', function (e) {
      var message = e.data;
      if (typeof message !== 'object') {
        message = JSON.parse(e.data);
      }
      if (message.subject === 'lti.lti2Registration') {
        this.props.handleInstall(message, e);
      }
    }.bind(this), false);

    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances());
    }
  },

  getLaunchUrl () {
    if (this.props.reregistration) {
      return this.props.registrationUrl
    }
    return 'about:blank';
  },

  handleAlertFocus (event) {
    const newState = {
      iframeStyle: { border: '2px solid #008EE2', width: `${(this.iframe.offsetWidth - 4)}px` }
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  },

  handleAlertBlur (event) {
    const newState = {
      iframeStyle: { border: 'none', width: '100%' }
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  },

  render () {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    return (
      <div id='lti2-iframe-container' style={this.props.hideComponent ? {display: 'none'} : {}}>
        <div className="ReactModal__Body" style={{padding: '0px !important', overflow: 'auto'}}>
          <div
            onFocus={this.handleAlertFocus}
            onBlur={this.handleAlertBlur}
            className={beforeAlertStyles}
            tabIndex="0"
          >
            <div className="ic-flash-info">
              <div className="ic-flash__icon" aria-hidden="true">
                <i className="icon-info" />
              </div>
              {I18n.t('The following content is partner provided')}
            </div>
          </div>
          <iframe
            src={this.getLaunchUrl()}
            name="lti2_registration_frame"
            className="tool_launch"
            title={I18n.t('Tool Content')}
            style={this.state.iframeStyle}
            ref={(e) => { this.iframe = e; }}
          />
          <div
            onFocus={this.handleAlertFocus}
            onBlur={this.handleAlertBlur}
            className={afterAlertStyles}
            tabIndex="0"
          >
            <div className="ic-flash-info">
              <div className="ic-flash__icon" aria-hidden="true">
                <i className="icon-info" />
              </div>
              {I18n.t('The preceding content is partner provided')}
            </div>
          </div>
        </div>
        {this.props.children}
      </div>
    )
  }
});
