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

import $ from 'jquery'
import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import Modal, { ModalBody } from '../../shared/components/InstuiModal'
import store from '../../external_apps/lib/ExternalAppsStore'
import ModalFooter from '@instructure/ui-overlays/lib/components/Modal/ModalFooter';
import Button from '@instructure/ui-buttons/lib/components/Button';

export default class Lti2ReregistrationUpdateModal extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    closeHandler: PropTypes.func,
    canAddEdit: PropTypes.bool.isRequired,
    returnFocus: PropTypes.func.isRequired
  }

  state = {
    modalIsOpen: false
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
    this.props.returnFocus()
  }

  acceptUpdate = e => {
    e.preventDefault()
    this.closeModal(() => {
      store.acceptUpdate(this.props.tool)
    })
  }

  dismissUpdate = e => {
    e.preventDefault()
    this.closeModal(() => {
      store.dismissUpdate(this.props.tool)
    })
  }

  render() {
    return (
      <Modal
        open={this.state.modalIsOpen}
        onDismiss={this.closeModal}
        label={I18n.t('Update %{tool}', {tool: this.props.tool.name})}
      >
        <ModalBody>
          {I18n.t('Would you like to accept or dismiss this update?')}
        </ModalBody>
        <ModalFooter>
          <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
          &nbsp;
          <Button onClick={this.dismissUpdate} variant="danger">{I18n.t('Dismiss')}</Button>
          &nbsp;
          <Button onClick={this.acceptUpdate} variant="primary">{I18n.t('Accept')}</Button>
        </ModalFooter>
      </Modal>
    )
  }
}
