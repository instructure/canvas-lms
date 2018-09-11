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

import React from 'react'
import Modal from 'react-modal'

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

class ReactModalExample extends React.Component {
  state = {
    modalIsOpen: false
  }

  openModal = () => {
    this.setState({modalIsOpen: true})
  }

  closeModal = () => {
    this.setState({modalIsOpen: false})
  }

  handleSubmit = e => {
    e.preventDefault()
    this.setState({modalIsOpen: false})
    alert('Submitted')
  }

  render() {
    return (
      <div className="ReactModalExample">
        <button type="button" className="btn btn-primary" onClick={this.openModal}>
          {this.props.label || 'Trigger Modal'}
        </button>
        <Modal
          isOpen={this.state.modalIsOpen}
          onRequestClose={this.closeModal}
          className={this.props.className}
          overlayClassName={this.props.overlayClassName}
          style={modalOverrides}
        >
          <div className="ReactModal__Layout">
            <div className="ReactModal__Header">
              <div className="ReactModal__Header-Title">
                <h4>Modal Title Goes Here</h4>
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
              Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus deserunt
              doloremque, explicabo illo ipsum libero magni odio officia optio perferendis ratione
              repellat suscipit tempore. Commodi hic sed. Lorem ipsum dolor sit amet, consectetur
              adipisicing elit. Accusamus deserunt doloremque, explicabo illo ipsum libero magni
              odio officia optio perferendis ratione repellat suscipit tempore. Commodi hic sed.
            </div>
            <div className="ReactModal__Footer">
              <div className="ReactModal__Footer-Actions">
                <button type="button" className="btn btn-default" onClick={this.closeModal}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" onClick={this.handleSubmit}>
                  Submit
                </button>
              </div>
            </div>
          </div>
        </Modal>
      </div>
    )
  }
}

export default ReactModalExample
