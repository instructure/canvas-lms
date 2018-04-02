/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!discussions_v2'
import React, { Component } from 'react'
import Button from '@instructure/ui-core/lib/components/Button'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '@instructure/ui-core/lib/components/Modal'
import Heading from '@instructure/ui-core/lib/components/Heading'
import { bool, func, number, node } from 'prop-types'

export default class DiscussionDeleteModal extends Component {
  static propTypes = {
    onSubmit: func.isRequired,
    selectedCount: number,
    defaultOpen: bool,
    applicationElement: node.isRequired
  }

  static defaultProps = {
    defaultOpen: true,
    selectedCount: 1
  }

  state ={
    open: this.props.defaultOpen
  }

  componentWillReceiveProps(props) {
    this.setState({ open: props.defaultOpen })
  }

  showDeleteConfirm = () => {
    this.setState({ open: true })
  }

  hideDeleteConfirm = () => {
    this.setState({ open: false }, () => {
      this.props.onSubmit({ isConfirm: false })
    })
  }

  confirmDelete = () => {
    this.setState({ open: false }, () => {
      this.props.onSubmit({ isConfirm: true })
    })
  }

  render() {
    return(
      <Modal
        open={this.state.open}
        onDismiss={this.hideDeleteConfirm}
        size="small"
        label={I18n.t('Confirm Delete Discussions')}
        closeButtonLabel={I18n.t('Close')}
        applicationElement={this.props.applicationElement}
        ref={(c) => { this.confirmDeleteModal = c }}
      >
        <ModalHeader>
          <Heading>{I18n.t('Confirm Delete')}</Heading>
        </ModalHeader>
        <ModalBody>
          {I18n.t({
            one: 'You are about to delete 1 discussion. Are you sure?',
            other: 'You are about to delete %{count} discussions. Are you sure?',
          }, { count: this.props.selectedCount })}
        </ModalBody>
        <ModalFooter>
          <Button
            ref={(c) => {this.cancelDeleteBtn = c}}
            onClick={this.hideDeleteConfirm}
          >{I18n.t('Cancel')}</Button>&nbsp;
          <Button
            ref={(c) => {this.confirmDeleteBtn = c}}
            id="confirm_delete_discussions"
            onClick={this.confirmDelete}
            variant="danger">{I18n.t('Delete')}</Button>
        </ModalFooter>
      </Modal>
    )
  }
}
