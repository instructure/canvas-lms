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
import {shape, func} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

const I18n = useI18nScope('external_tools')

export default class ConfigureExternalToolButton extends React.Component {
  static propTypes = {
    tool: shape({}).isRequired,
    returnFocus: func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      modalIsOpen: props.modalIsOpen,
      beforeExternalContentAlertClass: 'screenreader-only',
      afterExternalContentAlertClass: 'screenreader-only',
      iframeStyle: {},
    }
  }

  getLaunchUrl = toolConfiguration => {
    const toolConfigUrl = toolConfiguration.url || toolConfiguration.target_link_uri
    return `${ENV.CONTEXT_BASE_URL}/external_tools/retrieve?url=${encodeURIComponent(
      toolConfigUrl
    )}&display=borderless&placement=tool_configuration`
  }

  openModal = e => {
    e.preventDefault()
    this.setState({modalIsOpen: true})
  }

  closeModal = cb => {
    if (typeof cb === 'function') {
      this.setState({modalIsOpen: false}, cb)
    } else {
      this.setState({modalIsOpen: false})
    }
    this.props.returnFocus()
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

  renderIframe = () => {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    return (
      <div>
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
          src={this.getLaunchUrl(this.props.tool.tool_configuration)}
          title={I18n.t('Tool Configuration')}
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

  onAfterOpen = () => {
    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }
  }

  render() {
    return (
      <li role="presentation" className="ConfigureExternalToolButton">
        {/* TODO: use InstUI button */}
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          tabIndex="-1"
          ref="btnTriggerModal"
          role="menuitem"
          aria-label={I18n.t('Configure %{toolName} App', {toolName: this.props.tool.name})}
          className="icon-settings-2"
          onClick={this.openModal}
        >
          {I18n.t('Configure')}
        </a>
        <Modal
          open={this.state.modalIsOpen}
          onDismiss={this.closeModal}
          onEnter={this.onAfterOpen}
          label={I18n.t('Configure %{tool} App?', {tool: this.props.tool.name})}
          size="large"
        >
          <Modal.Body>{this.renderIframe()}</Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
          </Modal.Footer>
        </Modal>
      </li>
    )
  }
}
