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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

const I18n = useI18nScope('external_tools')

export default class Lti2Iframe extends React.Component {
  static propTypes = {
    reregistration: PropTypes.bool,
    registrationUrl: PropTypes.string,
    handleInstall: PropTypes.func.isRequired,
    hideComponent: PropTypes.bool,
    toolName: PropTypes.string.isRequired,
  }

  state = {
    beforeExternalContentAlertClass: 'screenreader-only',
    afterExternalContentAlertClass: 'screenreader-only',
    iframeStyle: {},
  }

  componentDidMount() {
    window.addEventListener('message', this.handleMessage, false)

    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }
  }

  componentWillUnmount() {
    window.removeEventListener('message', this.handleMessage, false)
  }

  getLaunchUrl = () => {
    if (this.props.reregistration) {
      return this.props.registrationUrl
    }
    return 'about:blank'
  }

  handleAlertFocus = event => {
    const newState = {
      iframeStyle: {border: '2px solid #0374B5', width: `${this.iframe.offsetWidth - 4}px`},
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  }

  handleAlertBlur = event => {
    const newState = {
      iframeStyle: {border: 'none', width: '100%'},
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  }

  handleMessage = event => {
    try {
      if (event.origin !== ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN) {
        return
      }

      let message = event.data
      if (typeof message !== 'object') {
        message = JSON.parse(event.data)
      }
      if (message.subject === 'lti.lti2Registration') {
        this.props.handleInstall(message, event)
      }
    } catch (_error) {
      // Something else posted the message.
    }
  }

  render() {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    return (
      <div
        id="lti2-iframe-container"
        style={this.props.hideComponent ? {display: 'none'} : {}}
        data-testid="lti2-iframe-container"
      >
        <div className="ReactModal__Body" style={{padding: '0px !important', overflow: 'auto'}}>
          <div
            onFocus={this.handleAlertFocus}
            onBlur={this.handleAlertBlur}
            className={beforeAlertStyles}
            // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
            tabIndex="0"
          >
            <div className="ic-flash-info">
              <div className="ic-flash__icon" aria-hidden="true">
                <i className="icon-info" />
              </div>
              {I18n.t('The following content is partner provided')}
            </div>
          </div>
          <ToolLaunchIframe
            src={this.getLaunchUrl()}
            name="lti2_registration_frame"
            title={this.props.toolName}
            style={this.state.iframeStyle}
            ref={e => {
              this.iframe = e
            }}
          />
          <div
            onFocus={this.handleAlertFocus}
            onBlur={this.handleAlertBlur}
            className={afterAlertStyles}
            // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
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
}
