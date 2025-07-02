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
import {shape, func, bool} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'
import {onLtiClosePostMessage} from '@canvas/lti/jquery/messages'

const I18n = createI18nScope('external_tools')

export default class ConfigureExternalToolButton extends React.Component {
  removeCloseListener
  btnTriggerModal = React.createRef()

  static propTypes = {
    tool: shape({}).isRequired,
    returnFocus: func.isRequired,
    modalIsOpen: bool,
  }

  constructor(props) {
    super(props)
    this.state = {
      modalIsOpen: props.modalIsOpen,
    }
  }

  componentDidMount() {
    this.removeCloseListener = onLtiClosePostMessage('tool_configuration', this.closeModal)
  }

  componentWillUnmount() {
    this.removeCloseListener?.()
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

  iframeStyle = () => {
    return {
      width: this.iframeWidth() || '100%',
      height: this.iframeHeight(),
      minHeight: this.iframeHeight(),
      border: 'none',
      padding: '2px',
    }
  }

  renderIframe = () => {
    return (
      <div>
        <ToolLaunchIframe
          src={this.getLaunchUrl(this.props.tool)}
          title={I18n.t('Tool Configuration')}
          style={this.iframeStyle()}
          ref={e => {
            this.iframe = e
          }}
        />
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
          ref={this.btnTriggerModal}
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
