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

import I18n from 'i18n!announcements_v2'
import React, {Component} from 'react'
import ReactDOM from 'react-dom'
import {func, number, node} from 'prop-types'

import Modal, {ModalBody, ModalFooter} from '../../shared/components/InstuiModal'
import Button from '@instructure/ui-buttons/lib/components/Button'

export function showConfirmDelete(props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'confirm-delete-modal-container')
  document.body.appendChild(parent)

  function showConfirmDeleteRef(modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(
    <ConfirmDeleteModal {...props} parent={parent} ref={showConfirmDeleteRef} />,
    parent
  )
}

export default class ConfirmDeleteModal extends Component {
  static propTypes = {
    selectedCount: number.isRequired,
    onConfirm: func.isRequired,
    onCancel: func,
    onHide: func,
    modalRef: func,
    parent: node
  }

  static defaultProps = {
    onCancel: null,
    onHide: null,
    parent: null,
    modalRef: null
  }

  state = {
    show: false
  }

  componentDidMount() {
    if (this.props.modalRef) this.props.modalRef(this)
  }

  componentWillUnmount() {
    if (this.props.modalRef) this.props.modalRef(null)
  }

  onCancel = () => {
    if (this.props.onCancel) setTimeout(this.props.onCancel)
    this.hide()
  }

  onConfirm = () => {
    setTimeout(this.props.onConfirm)
    this.hide()
  }

  show() {
    this.setState({show: true})
  }

  hide() {
    this.setState({show: false}, () => {
      if (this.props.onHide) setTimeout(this.props.onHide)
      if (this.props.parent) ReactDOM.unmountComponentAtNode(this.props.parent)
    })
  }

  render() {
    return (
      <Modal
        open={this.state.show}
        onDismiss={this.onCancel}
        size="small"
        label={I18n.t('Confirm Delete')}
      >
        <ModalBody>
          {I18n.t(
            {
              one: 'You are about to delete 1 announcement. Are you sure?',
              other: 'You are about to delete %{count} announcements. Are you sure?'
            },
            {count: this.props.selectedCount}
          )}
        </ModalBody>
        <ModalFooter>
          <Button
            id="cancel_delete_announcements"
            ref={c => {
              this.cancelBtn = c
            }}
            onClick={this.onCancel}
          >
            {I18n.t('Cancel')}
          </Button>&nbsp;
          <Button
            ref={c => {
              this.confirmBtn = c
            }}
            id="confirm_delete_announcements"
            onClick={this.onConfirm}
            variant="danger"
          >
            {I18n.t('Delete')}
          </Button>
        </ModalFooter>
      </Modal>
    )
  }
}
