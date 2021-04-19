/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {Button} from '@instructure/ui-buttons'
import {FormField} from '@instructure/ui-form-field'
import I18n from 'i18n!eportfolio'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import PropTypes from 'prop-types'
import React from 'react'

class MoveToDialog extends React.Component {
  static propTypes = {
    header: PropTypes.string.isRequired,
    source: PropTypes.object.isRequired,
    destinations: PropTypes.arrayOf(PropTypes.object).isRequired,
    onMove: PropTypes.func,
    onClose: PropTypes.func,
    appElement: PropTypes.object,
    triggerElement: PropTypes.object
  }

  state = {
    isOpen: true
  }

  handleMove = () => {
    if (this.props.onMove) {
      this.props.onMove(this.refs.select.value)
    }
    this.handleRequestClose()
  }

  handleRequestClose = () => {
    this.setState({isOpen: false})
  }

  handleClose = () => {
    if (this.props.appElement) {
      this.props.appElement.removeAttribute('aria-hidden')
    }
    if (this.props.triggerElement) {
      this.props.triggerElement.focus()
    }
    if (this.props.onClose) {
      this.props.onClose()
    }
  }

  handleReady = () => {
    if (this.props.appElement) {
      this.props.appElement.setAttribute('aria-hidden', true)
    }
  }

  renderBody = () => {
    const selectLabel = I18n.t('Place "%{section}" before:', {
      section: this.props.source.label
    })

    return (
      <FormField id="MoveToDialog__formfield" label={selectLabel}>
        <select id="MoveToDialog__select" ref="select">
          {this.props.destinations.map(dest => (
            <option key={dest.id} value={dest.id}>
              {dest.label}
            </option>
          ))}
          <option key="move-to-dialog_at-the-bottom" value="">
            {I18n.t('-- At the bottom --')}
          </option>
        </select>
      </FormField>
    )
  }

  render() {
    return (
      <Modal
        ref="modal"
        open={this.state.isOpen}
        modalSize="small"
        label={this.props.header}
        onOpen={this.handleReady}
        onDismiss={this.handleRequestClose}
        onClose={this.handleClose}
      >
        <Modal.Body>{this.renderBody()}</Modal.Body>
        <Modal.Footer>
          <Button id="MoveToDialog__cancel" onClick={this.handleRequestClose}>
            {I18n.t('Cancel')}
          </Button>
          <Button id="MoveToDialog__move" variant="primary" onClick={this.handleMove}>
            {I18n.t('Move')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}

export default MoveToDialog
