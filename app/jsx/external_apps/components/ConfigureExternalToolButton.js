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

import $ from 'jquery'
import I18n from 'i18n!external_tools'
import React from 'react'
import {shape, func} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Modal, {ModalBody, ModalFooter}  from '../../shared/components/InstuiModal'
import iframeAllowances from '../lib/iframeAllowances'

export default class ConfigureExternalToolButton extends React.Component {
  static propTypes = {
    tool: shape({}).isRequired,
    returnFocus: func.isRequired
  }

  constructor (props) {
    super(props)
    this.state = {
      modalIsOpen: props.modalIsOpen,
      beforeExternalContentAlertClass: 'screenreader-only',
      afterExternalContentAlertClass: 'screenreader-only',
      iframeStyle: {}
    }
  }

  getLaunchUrl = () => {
    const toolConfigUrl = this.props.tool.tool_configuration.url
    return `${ENV.CONTEXT_BASE_URL}/external_tools/retrieve?url=${encodeURIComponent(
      toolConfigUrl
    )}&display=borderless`
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
      iframeStyle: {border: '2px solid #008EE2', width: `${this.iframe.offsetWidth - 4}px`}
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
      iframeStyle: {border: 'none', width: '100%'}
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  }

  renderIframe = () => {
    const beforeAlertStyles = `before_external_content_info_alert ${
      this.state.beforeExternalContentAlertClass
    }`
    const afterAlertStyles = `after_external_content_info_alert ${
      this.state.afterExternalContentAlertClass
    }`

    return (
      <div>
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
          title={I18n.t('Tool Configuration')}
          className="tool_launch"
          style={this.state.iframeStyle}
          ref={e => {
            this.iframe = e
          }}
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
          <ModalBody>{this.renderIframe()}</ModalBody>
          <ModalFooter>
            <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
          </ModalFooter>
        </Modal>
      </li>
    )
  }
}
