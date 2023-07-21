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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

const I18n = useI18nScope('collaborations')

let main

class CollaborationsToolLaunch extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      height: 500,
      beforeExternalContentAlertClass: 'screenreader-only',
      afterExternalContentAlertClass: 'screenreader-only',
      iframeStyle: {},
    }

    main = document.querySelector('#main')
  }

  componentDidMount() {
    this.setHeight()
    window.addEventListener('resize', this.setHeight)

    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.setHeight)
  }

  setHeight = () => {
    this.setState({
      height: main.getBoundingClientRect().height - 48,
    })
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

  render() {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    return (
      <div className="CollaborationsToolLaunch" style={{height: this.state.height}}>
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
          src={this.props.launchUrl}
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
    )
  }
}

export default CollaborationsToolLaunch
