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

import React from 'react'
import $ from 'jquery'
import _ from 'underscore'
import preventDefault from 'compiled/fn/preventDefault'
import ReactModal from 'react-modal'
import ModalContent from './modal-content'
import ModalButtons from './modal-buttons'

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

export default class Modal extends React.Component {
  static defaultProps = {
    className: 'ReactModal__Content--canvas', // Override with "ReactModal__Content--canvas ReactModal__Content--mini-modal" for a mini modal
    style: {}
  }

  state = {
    modalIsOpen: this.props.isOpen
  }

  componentWillReceiveProps(props) {
    let callback
    if (this.props.isOpen && !props.isOpen) callback = this.cleanupAfterClose
    this.setState({modalIsOpen: props.isOpen}, callback)
  }

  openModal = () => {
    this.setState({modalIsOpen: true})
  }

  cleanupAfterClose = () => {
    if (this.props.onRequestClose) this.props.onRequestClose()
    $(this.getAppElement()).removeAttr('aria-hidden')
  }

  closeModal = () => {
    this.setState({modalIsOpen: false}, this.cleanupAfterClose)
  }

  closeWithX = () => {
    if (_.isFunction(this.props.closeWithX)) this.props.closeWithX()
    this.closeModal()
  }

  onSubmit = () => {
    const promise = this.props.onSubmit()
    $(this.modal).disableWhileLoading(promise)
  }

  onAfterOpen = () => {
    this.closeBtn.focus()
    if (this.props.onAfterOpen) {
      this.props.onAfterOpen()
    }
  }

  getAppElement = () =>
    // Need to wait for the dom to load before we can get the default #application dom element
     this.props.appElement || document.getElementById('application')


  processMultipleChildren = props => {
    let content = null
    let buttons = null

    React.Children.forEach(props.children, (child) => {
      if (child.type === ModalContent) {
        content = child
      } else if (child.type === ModalButtons) {
        buttons = child
      } else {
        // Warning if you don't include a component of the right type
        console.warn('Modal chilren must be wrapped in either a modal-content or modal-buttons component.')
      }
    })

    if (this.props.onSubmit) {
      return (
        <form className="ModalForm" onSubmit={preventDefault(this.onSubmit)}>
          {[content, buttons]}
        </form>
      )
    } else {
      return [content, buttons] // This order needs to be maintained
    }
  }

  render() {
    return (
      <div className="canvasModal">
        <ReactModal
          ariaHideApp={!!this.state.modalIsOpen}
          isOpen={!!this.state.modalIsOpen}
          onRequestClose={this.closeModal}
          className={this.props.className}
          style={modalOverrides}
          onAfterOpen={this.onAfterOpen}
          overlayClassName={this.props.overlayClassName}
          contentLabel={this.props.contentLabel}
          appElement={this.getAppElement()}
        >
          <div
            ref={c => {
              this.modal = c
            }}
            className="ReactModal__Layout"
            style={this.props.style}
          >
            <div className="ReactModal__Header">
              <div className="ReactModal__Header-Title">
                <h4>{this.props.title}</h4>
              </div>
              <div className="ReactModal__Header-Actions">
                <button
                  ref={c => {
                    this.closeBtn = c
                  }}
                  className="Button Button--icon-action"
                  type="button"
                  onClick={this.closeWithX}
                >
                  <i className="icon-x" />
                  <span className="screenreader-only">Close</span>
                </button>
              </div>
            </div>
            {this.processMultipleChildren(this.props)}
          </div>
        </ReactModal>
      </div>
    )
  }
}
