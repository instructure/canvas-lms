/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import React, {Component} from 'react'
import {func, string, bool} from 'prop-types'
import {Button} from '@instructure/ui-buttons'

import Modal from '@canvas/instui-bindings/react/InstuiModal'

const I18n = useI18nScope('confirmMasteryModal')

export default class ConfirmMasteryModal extends Component {
  static propTypes = {
    onConfirm: func.isRequired,
    modalText: string.isRequired,
    isOpen: bool.isRequired,
    onClose: func.isRequired,
    title: string.isRequired,
    confirmButtonText: string,
  }

  static defaultProps = {
    confirmButtonText: I18n.t('Save'),
  }

  onConfirm = () => {
    this.props.onConfirm()
  }

  onClose = () => {
    this.props.onClose()
  }

  render() {
    return (
      <Modal
        label={this.props.title}
        open={this.props.isOpen}
        onDismiss={this.onClose}
        size="small"
      >
        <Modal.Body>
          <div>{this.props.modalText}</div>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.onClose}>{I18n.t('Cancel')}</Button>
          &nbsp;
          <Button onClick={this.onConfirm} color="primary">
            {this.props.confirmButtonText}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
