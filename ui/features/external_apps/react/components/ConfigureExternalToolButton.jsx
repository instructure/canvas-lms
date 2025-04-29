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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {shape, func} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'

const I18n = createI18nScope('external_tools')

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
      alertFocused: false,
    }
  }

  getLaunchUrl = tool => {
    return `${ENV.CONTEXT_BASE_URL}/external_tools/${tool.app_id}?display=borderless&placement=tool_configuration`
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
    const newState = {alertFocused: true}
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  }

  iframeStyle = () => {
    const alertFocused = this.state?.alertFocused
    return {
      width: this.iframeWidth() || '100%',
      height: this.iframeHeight(),
      minHeight: this.iframeHeight(),
      border: alertFocused ? '2px solid #2B7ABC' : 'none',
      padding: alertFocused ? '0px' : '2px',
    }
  }

  handleAlertBlur = event => {
    const newState = {alertFocused: false}
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
          <div className="ic-flash-info" style={{maxWidth: this.headingWidth()}}>
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The following content is partner provided')}
          </div>
        </div>
        <ToolLaunchIframe
          src={this.getLaunchUrl(this.props.tool)}
          title={I18n.t('Tool Configuration')}
          style={this.iframeStyle()}
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

  iframeWidth = () => this.props.tool?.tool_configuration.selection_width || undefined
  iframeHeight = () => this.props.tool?.tool_configuration.selection_height || undefined
  modalSize = () => (this.iframeWidth() ? undefined : 'large')
  // If we don't explicitly set header width, long tool names will cause header
  // to be wider than iframe (plus 40 pixels for close button / padding) and
  // make dialog be too wide.
  headingWidth = () => ((this.iframeWidth() || 0) > 50 ? this.iframeWidth() - 40 : undefined)

  render() {
    const title = I18n.t('Configure %{toolName} App', {toolName: this.props.tool.name})

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
          label={title}
          size={this.modalSize()}
        >
          <Modal.Header style={{width: this.headingWidth()}} width={this.headingWidth()}>
            <CloseButton
              onClick={this.closeModal}
              offset="medium"
              placement="end"
              screenReaderLabel={I18n.t('Close')}
            />
            <Heading width={this.headingWidth()} style={{width: this.headingWidth()}}>
              {title}
            </Heading>
          </Modal.Header>
          <Modal.Body>{this.renderIframe()}</Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal} data-testid="close-modal-button">
              {I18n.t('Close')}
            </Button>
          </Modal.Footer>
        </Modal>
      </li>
    )
  }
}
