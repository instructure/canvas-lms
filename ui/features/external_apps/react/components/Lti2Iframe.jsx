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
import PropTypes from 'prop-types'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

export default class Lti2Iframe extends React.Component {
  static propTypes = {
    reregistration: PropTypes.bool,
    registrationUrl: PropTypes.string,
    handleInstall: PropTypes.func.isRequired,
    hideComponent: PropTypes.bool,
    toolName: PropTypes.string.isRequired,
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
    return (
      <div
        id="lti2-iframe-container"
        style={this.props.hideComponent ? {display: 'none'} : {}}
        data-testid="lti2-iframe-container"
      >
        <div className="ReactModal__Body" style={{padding: '0px !important', overflow: 'auto'}}>
          <ToolLaunchIframe
            src={this.getLaunchUrl()}
            name="lti2_registration_frame"
            title={this.props.toolName}
            ref={e => {
              this.iframe = e
            }}
          />
        </div>
        {this.props.children}
      </div>
    )
  }
}
