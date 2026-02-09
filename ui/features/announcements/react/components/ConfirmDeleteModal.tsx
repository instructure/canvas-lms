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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import ReactDOM from 'react-dom'
import {func, number, node, object, oneOfType} from 'prop-types'

import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'

const I18n = createI18nScope('announcements_v2')

// @ts-expect-error TS7006 (typescriptify)
export function showConfirmDelete(props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'confirm-delete-modal-container')
  document.body.appendChild(parent)

  // @ts-expect-error TS7006 (typescriptify)
  function showConfirmDeleteRef(modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(
    <ConfirmDeleteModal {...props} parent={parent} ref={showConfirmDeleteRef} />,
    parent,
  )
}

export default class ConfirmDeleteModal extends Component {
  static propTypes = {
    selectedCount: number.isRequired,
    onConfirm: func.isRequired,
    onCancel: func,
    onHide: func,
    modalRef: func,
    parent: oneOfType([node, object]),
  }

  static defaultProps = {
    onCancel: null,
    onHide: null,
    parent: null,
    modalRef: null,
  }

  state = {
    show: false,
  }

  componentDidMount() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.modalRef) this.props.modalRef(this)
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.modalRef) this.props.modalRef(null)
  }

  onCancel = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.onCancel) setTimeout(this.props.onCancel)
    this.hide()
  }

  onConfirm = () => {
    // @ts-expect-error TS2339 (typescriptify)
    setTimeout(this.props.onConfirm)
    this.hide()
  }

  show() {
    this.setState({show: true})
  }

  hide() {
    this.setState({show: false}, () => {
      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.onHide) setTimeout(this.props.onHide)
      // @ts-expect-error TS2339 (typescriptify)
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
        <Modal.Body>
          {I18n.t(
            {
              one: 'You are about to delete 1 announcement. Are you sure?',
              other: 'You are about to delete %{count} announcements. Are you sure?',
            },
            // @ts-expect-error TS2339 (typescriptify)
            {count: this.props.selectedCount},
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            id="cancel_delete_announcements"
            data-testid="cancel-delete-announcements"
            ref={c => {
              // @ts-expect-error TS2339 (typescriptify)
              this.cancelBtn = c
            }}
            onClick={this.onCancel}
          >
            {I18n.t('Cancel')}
          </Button>
          &nbsp;
          <Button
            ref={c => {
              // @ts-expect-error TS2339 (typescriptify)
              this.confirmBtn = c
            }}
            id="confirm_delete_announcements"
            data-testid="confirm-delete-announcements"
            onClick={this.onConfirm}
            color="danger"
          >
            {I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
