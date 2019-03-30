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
import {bool, func, string, shape} from 'prop-types'
import I18n from 'i18n!assignments_2'

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
import View from '@instructure/ui-layout/lib/components/View'

export default class ConfirmDialog extends React.Component {
  static propTypes = {
    open: bool,

    // set to true to disable the close buttons and the footer buttons
    disabled: bool,

    // set to true to show the busy mask
    working: bool,

    // return what should be in the body of the dialog
    body: func.isRequired,

    // return array of property objects to create buttons in the footer.
    // pass the children of the Button (usually the display text) as a `children` property
    buttons: func,

    // returns what should be on the mask when the dialog is busy. Defaults to a small spinner.
    busyMaskBody: func,

    // label to use if using the default spinner busy mask
    spinnerLabel: string,

    heading: string.isRequired,
    modalLabel: string, // defaults to heading

    // properties to pass to the modal
    modalProps: shape(Modal.propTypes),

    closeLabel: string,

    // invoked when the close button is clicked
    onDismiss: func
  }

  static defaultProps = {
    open: false,
    working: false,
    disabled: false,
    buttons: () => [],

    modalProps: {},
    closeLabel: I18n.t('close'),
    spinnerLabel: I18n.t('working...'),
    onDismiss: () => {}
  }

  closeButtonRef(elt) {
    // because data-testid ends up on the wrong element if we just pass it through to the close button
    if (elt) {
      elt.setAttribute('data-testid', 'confirm-dialog-close-button')
    }
  }

  modalLabel() {
    return this.props.modalLabel ? this.props.modalLabel : this.props.heading
  }

  renderBusyMaskBody() {
    if (this.props.busyMaskBody) return this.props.busyMaskBody()
    return <Spinner size="small" title={this.props.spinnerLabel} />
  }

  renderButton = (buttonProps, index) => {
    const defaultProps = {
      key: index,
      disabled: this.props.disabled,
      margin: '0 x-small 0 0'
    }
    const props = {...defaultProps, ...buttonProps}
    return <Button {...props} />
  }

  render() {
    return (
      this.props.open && ( // Don't waste time rendering anything if it is not open
        <Modal {...this.props.modalProps} label={this.modalLabel()} open={this.props.open}>
          <ModalHeader>
            <Heading level="h2">{this.props.heading}</Heading>
            <CloseButton
              placement="end"
              onClick={this.props.onDismiss}
              disabled={this.props.disabled}
              buttonRef={this.closeButtonRef}
            >
              {this.props.closeLabel}
            </CloseButton>
          </ModalHeader>
          <ModalBody padding="0">
            <div style={{position: 'relative'}}>
              <View as="div" padding="medium">
                {this.props.body()}
                {this.props.working ? <Mask>{this.renderBusyMaskBody()}</Mask> : null}
              </View>
            </div>
          </ModalBody>
          <ModalFooter>{this.props.buttons().map(this.renderButton)}</ModalFooter>
        </Modal>
      )
    )
  }
}
