/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func, string} from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'

import Mask from '@instructure/ui-overlays/lib/components/Mask'
import Modal, {
  ModalHeader,
  ModalBody,
  ModalFooter
} from '@instructure/ui-overlays/lib/components/Modal'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'

export default class ConfirmDialog extends React.Component {
  static propTypes = {
    open: bool,
    working: bool,

    modalLabel: string, // defaults to heading
    heading: string,
    message: string.isRequired,
    confirmLabel: string.isRequired,
    cancelLabel: string.isRequired,
    closeLabel: string.isRequired,
    spinnerLabel: string.isRequired,

    onClose: func,
    onConfirm: func,
    onCancel: func
  }

  static defaultProps = {
    open: false,
    heading: '',
    onClose: () => {},
    onConfirm: () => {},
    onCancel: () => {}
  }

  setTestIdCloseButton(buttonElt) {
    if (!buttonElt) return
    buttonElt.setAttribute('data-testid', 'confirm-dialog-close-button')
  }

  setTestIdCancelButton(buttonElt) {
    if (!buttonElt) return
    buttonElt.setAttribute('data-testid', 'confirm-dialog-cancel-button')
  }

  setTestIdConfirmButton(buttonElt) {
    if (!buttonElt) return
    buttonElt.setAttribute('data-testid', 'confirm-dialog-confirm-button')
  }

  modalLabel() {
    return this.props.modalLabel ? this.props.modalLabel : this.props.heading
  }

  render() {
    return (
      <Modal label={this.modalLabel()} open={this.props.open}>
        <ModalHeader>
          <Heading level="h2">{this.props.heading}</Heading>
          <CloseButton
            placement="end"
            onClick={this.props.onClose}
            buttonRef={this.setTestIdCloseButton}
            disabled={this.props.working}
          >
            {this.props.closeLabel}
          </CloseButton>
        </ModalHeader>
        <ModalBody padding="0">
          <View as="div" padding="medium" style={{position: 'relative'}}>
            <Text size="large">{this.props.message}</Text>
            {this.props.working ? (
              <Mask>
                <Spinner size="small" title={this.props.spinnerLabel} />
              </Mask>
            ) : null}
          </View>
        </ModalBody>
        <ModalFooter>
          <Button
            onClick={this.props.onCancel}
            margin="0 x-small 0 0"
            disabled={this.props.working}
            buttonRef={this.setTestIdCancelButton}
          >
            {this.props.cancelLabel}
          </Button>
          <Button
            variant="danger"
            onClick={this.props.onConfirm}
            margin="0 x-small 0 0"
            disabled={this.props.working}
            buttonRef={this.setTestIdConfirmButton}
          >
            {this.props.confirmLabel}
          </Button>
        </ModalFooter>
      </Modal>
    )
  }
}
