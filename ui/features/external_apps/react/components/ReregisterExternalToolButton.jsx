/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import Lti2Iframe from './Lti2Iframe'
import Lti2ReregistrationUpdateModal from './Lti2ReregistrationUpdateModal'
import store from '../lib/ExternalAppsStore'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('external_tools')

export default class ReregisterExternalToolButton extends React.Component {
  state = {
    tool: this.props.tool,
    modalIsOpen: false,
  }

  componentDidUpdate() {
    const _this = this
    window.requestAnimationFrame(() => {
      const node = document.getElementById(`close${_this.state.tool.name}`)
      if (node) {
        node.focus()
      }
    })
  }

  openModal = e => {
    e.preventDefault()
    this.setState({
      tool: this.props.tool,
      modalIsOpen: true,
    })
  }

  closeModal = () => {
    this.setState({modalIsOpen: false})
    this.props.returnFocus()
  }

  handleReregistration = (_message, e) => {
    this.props.tool.has_update = true
    store.triggerUpdate()
    this.closeModal()
    this.refs.reregModal.openModal(e)
  }

  getModal = () => (
    <Modal
      ref="reactModal"
      open={this.state.modalIsOpen}
      onDismiss={this.closeModal}
      label={I18n.t('App Reregistration')}
    >
      <Modal.Body>
        <Lti2Iframe
          ref="lti2Iframe"
          handleInstall={this.handleReregistration}
          registrationUrl={this.props.tool.reregistration_url}
          reregistration={true}
          toolName={this.props.tool.name || I18n.t('Tool Content')}
        />
      </Modal.Body>
    </Modal>
  )

  getButton = () => {
    const editAriaLabel = I18n.t('Reregister %{toolName}', {toolName: this.state.tool.name})
    return (
      // TODO: use InstUI button
      // eslint-disable-next-line jsx-a11y/anchor-is-valid
      <a
        href="#"
        tabIndex="-1"
        ref="reregisterExternalToolButton"
        role="menuitem"
        aria-label={editAriaLabel}
        className="icon-refresh"
        onClick={this.openModal}
      >
        {I18n.t('Reregister')}
      </a>
    )
  }

  render() {
    if ((this.props.canAdd || this.props.canAddEdit) && this.props.tool.reregistration_url) {
      return (
        <li role="presentation" className="ReregisterExternalToolButton">
          {this.getButton()}
          {this.getModal()}
          <Lti2ReregistrationUpdateModal tool={this.props.tool} ref="reregModal" />
        </li>
      )
    }
    return false
  }
}
