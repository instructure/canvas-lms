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
import {shape, string, arrayOf} from 'prop-types'
import Modal, {ModalBody} from '../shared/components/InstuiModal'
import I18n from 'i18n!keyboardShortcutModal'

export default class KeyboardShortcutModal extends React.Component {
  static propTypes = {
    shortcuts: arrayOf(
      shape({
        keycode: string.isRequired,
        description: string.isRequired
      })
    )
  }

  static defaultProps = {
    shortcuts: []
  }

  state = {
    isOpen: false
  }

  componentDidMount() {
    document.addEventListener('keydown', this.handleKeydown)
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this.handleKeydown)
  }

  closeModal = () => {
    this.setState({isOpen: false})
  }

  handleKeydown = e => {
    // 188 is comma and 191 is forward slash
    const keyComboPressed = e.which === 188 || (e.which === 191 && e.shiftKey)
    if (keyComboPressed && e.target.nodeName !== 'INPUT' && e.target.nodeName !== 'TEXTAREA') {
      e.preventDefault()
      this.setState({isOpen: !this.state.isOpen})
    }
  }

  render() {
    return (
      <Modal
        open={this.state.isOpen}
        label={I18n.t('Keyboard Shortcuts')}
        onDismiss={this.closeModal}
      >
        <ModalBody>
          <div className="keyboard_navigation">
            <span className="screenreader-only">
              {I18n.t(
                'Users of screen readers may need to turn off the virtual cursor in order to use these keyboard shortcuts'
              )}
            </span>
            <ul className="navigation_list">
              {this.props.shortcuts.map(shortcut => (
                <li key={shortcut.keycode}>
                  <span className="keycode">{shortcut.keycode}</span>
                  <span className="colon">:</span>
                  <span className="description">{shortcut.description}</span>
                </li>
              ))}
            </ul>
            <span className="screenreader-only">
              {I18n.t('Press the esc key to close this modal')}
            </span>
          </div>
        </ModalBody>
      </Modal>
    )
  }
}
