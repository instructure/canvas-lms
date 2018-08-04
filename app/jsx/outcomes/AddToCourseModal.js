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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!outcomes'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Modal, { ModalBody, ModalFooter } from '../shared/components/InstuiModal'
import Text from '@instructure/ui-elements/lib/components/Text'

export default class AddToCourseModal extends React.Component {
  static propTypes = {
    onClose: PropTypes.func.isRequired,
    onReady: PropTypes.func.isRequired
  }

  getInitialState () {
    return {
      isOpen: false
    }
  }

  close () {
    this.setState({ isOpen: false });
  }

  open () {
    this.setState({ isOpen: true });
  }

  /*
   * TODO: Remove these next two functions once INSTUI fixes initial focus being
   * set incorrectly when opening a modal
   */
  _saveModal = (modal) => {
    this._modal = modal;
  }

  _fixFocus = () => {
    setTimeout(() => {
      this._modal._closeButton.focus();
    }, 0);
  }

  render () {
    return (
      <Modal
        open={this.state.isOpen}
        shouldCloseOnOverlayClick
        onDismiss={this.close}
        transition="fade"
        size="auto"
        label={I18n.t("Add to course...")}
        ref={this._saveModal}
        onEntering={this._fixFocus}
        onClose={this.props.onClose}
        onOpen={this.props.onReady}
      >
        <ModalBody>
          <Text lineHeight="double">Add to course functionality goes here...</Text>
        </ModalBody>
        <ModalFooter>
          <Button onClick={this.close} variant="primary">{I18n.t("Close")}</Button>
        </ModalFooter>
      </Modal>
    );
  }
}
