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
import PropTypes from 'prop-types'
import Modal from 'react-modal'
import store from '../../external_apps/lib/ExternalAppsStore'

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

export default class DeleteExternalToolButton extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired
  }

  state = {
    modalIsOpen: false
  }

  isDeleting = false

  shouldComponentUpdate() {
    return !this.isDeleting
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

  deleteTool = e => {
    e.preventDefault()
    this.isDeleting = true
    this.closeModal(() => {
      store.delete(this.props.tool)
      this.isDeleting = false
    })
  }

  render() {
    if (this.props.canAddEdit) {
      return (
        <li role="presentation" className="DeleteExternalToolButton">
          <a
            href="#"
            tabIndex="-1"
            ref="btnTriggerDelete"
            role="button"
            aria-label={I18n.t('Delete %{toolName} App', {toolName: this.props.tool.name})}
            className="icon-trash"
            onClick={this.openModal}
          >
            {I18n.t('Delete')}
          </a>
          <Modal
            className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
            overlayClassName="ReactModal__Overlay--canvas"
            style={modalOverrides}
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}
          >
            <div className="ReactModal__Layout">
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Delete %{tool} App?', {tool: this.props.tool.name})}</h4>
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
                {I18n.t('Are you sure you want to remove this tool?')}
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
                    onClick={this.deleteTool}
                  >
                    {I18n.t('Delete')}
                  </button>
                </div>
              </div>
            </div>
          </Modal>
        </li>
      )
    }
    return false;
  }
}
