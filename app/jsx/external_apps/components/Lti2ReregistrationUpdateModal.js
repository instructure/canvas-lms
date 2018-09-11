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

import $ from 'jquery'
import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from 'react-modal'
import store from '../../external_apps/lib/ExternalAppsStore'

export default class Lti2ReregistrationUpdateModal extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    closeHandler: PropTypes.func,
    canAddEdit: PropTypes.bool.isRequired
  }

  state = {
    modalIsOpen: false
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

  acceptUpdate = e => {
    e.preventDefault()
    this.closeModal(() => {
      store.acceptUpdate(this.props.tool)
    })
  }

  dismissUpdate = e => {
    e.preventDefault()
    this.closeModal(() => {
      store.dismissUpdate(this.props.tool)
    })
  }

  render() {
    return (
      <Modal
        className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
        overlayClassName="ReactModal__Overlay--canvas"
        isOpen={this.state.modalIsOpen}
        onRequestClose={this.closeModal}
      >
        <div className="ReactModal__Layout">
          <div className="ReactModal__Header">
            <div className="ReactModal__Header-Title">
              <h4>{I18n.t('Update %{tool}', {tool: this.props.tool.name})}</h4>
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

          <div className="ReactModal__Body">
            {I18n.t('Would you like to accept or dismiss this update?')}
          </div>

          <div className="ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              <button ref="btnClose" type="button" className="Button" onClick={this.closeModal}>
                {I18n.t('Close')}
              </button>
              <button
                ref="btnDelete"
                type="button"
                className="Button Button--danger"
                onClick={this.dismissUpdate}
              >
                {I18n.t('Dismiss')}
              </button>
              <button
                ref="btnAccept"
                type="button"
                className="Button Button--primary"
                onClick={this.acceptUpdate}
              >
                {I18n.t('Accept')}
              </button>
            </div>
          </div>
        </div>
      </Modal>
    )
  }
}
