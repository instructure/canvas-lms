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
import {useScope as useI18nScope} from '@canvas/i18n'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Mask} from '@instructure/ui-overlays'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('assignments_2')

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
    modalProps: shape({
      // by default Modal.propTypes.label "isRequired" but ours is not because we fall back to this.props.heading
      ...Modal.propTypes,
      label: string,
    }),

    closeLabel: string,

    // invoked when the close button is clicked
    onDismiss: func,
  }

  static defaultProps = {
    open: false,
    working: false,
    disabled: false,
    buttons: () => [],

    modalProps: {},
    closeLabel: I18n.t('close'),
    spinnerLabel: I18n.t('working...'),
    onDismiss: () => {},
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
    return <Spinner size="small" renderTitle={this.props.spinnerLabel} />
  }

  renderButton = (buttonProps, index) => {
    const defaultProps = {
      key: index,
      disabled: this.props.disabled,
      margin: '0 x-small 0 0',
    }
    const props = {...defaultProps, ...buttonProps}
    return <Button {...props} />
  }

  render() {
    return (
      this.props.open && ( // Don't waste time rendering anything if it is not open
        <Modal
          {...this.props.modalProps}
          label={this.modalLabel()}
          open={this.props.open}
          onDismiss={this.props.onDismiss}
        >
          <Modal.Header>
            <Heading level="h2">{this.props.heading}</Heading>
            <CloseButton
              placement="end"
              onClick={this.props.onDismiss}
              disabled={this.props.disabled}
              elementRef={this.closeButtonRef}
              screenReaderLabel={this.props.closeLabel}
            />
          </Modal.Header>
          <Modal.Body padding="0">
            <div style={{position: 'relative'}}>
              <View as="div" padding="medium">
                {this.props.body()}
                {this.props.working ? <Mask>{this.renderBusyMaskBody()}</Mask> : null}
              </View>
            </div>
          </Modal.Body>
          <Modal.Footer>{this.props.buttons().map(this.renderButton)}</Modal.Footer>
        </Modal>
      )
    )
  }
}
