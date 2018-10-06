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
import {shape} from 'prop-types'
import Modal from 'react-modal'
import iframeAllowances from '../lib/iframeAllowances'

const modalOverrides = {
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  },
  content: {
    position: 'static',
    top: '0',
    left: '0',
    right: 'auto',
    bottom: 'auto',
    borderRadius: '0',
    border: 'none',
    padding: '0'
  }
}

export default class ConfigureExternalToolButton extends React.Component {
  static propTypes = {
    tool: shape({}).isRequired
  }

  state = {
    modalIsOpen: false,
    beforeExternalContentAlertClass: 'screenreader-only',
    afterExternalContentAlertClass: 'screenreader-only',
    iframeStyle: {}
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
          className="ReactModal__Content--canvas"
          overlayClassName="ReactModal__Overlay--canvas"
          style={modalOverrides}
          isOpen={this.state.modalIsOpen}
          onRequestClose={this.closeModal}
          onAfterOpen={this.onAfterOpen}
        >
          <div className="ReactModal__Layout">
            <div className="ReactModal__Header">
              <div className="ReactModal__Header-Title">
                <h4>{I18n.t('Configure %{tool} App?', {tool: this.props.tool.name})}</h4>
              </div>
              <div className="ReactModal__Header-Actions">
                <button
                  className="Button Button--icon-action"
                  type="button"
                  onClick={this.closeModal}
                >
                  <i className="icon-x" />
                  <span className="screenreader-only">Close</span>
                </button>
              </div>
            </div>

            <div
              className="ReactModal__Body ReactModal__Body--force-no-padding"
              style={{overflow: 'auto'}}
            >
              {this.renderIframe()}
            </div>

            <div className="ReactModal__Footer">
              <div className="ReactModal__Footer-Actions">
                <button ref="btnClose" type="button" className="Button" onClick={this.closeModal}>
                  {I18n.t('Close')}
                </button>
              </div>
            </div>
          </div>
        </Modal>
      </li>
    )
  }
}
