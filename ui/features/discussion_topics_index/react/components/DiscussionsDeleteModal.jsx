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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {bool, func, number} from 'prop-types'

const I18n = useI18nScope('discussions_v2')

export default class DiscussionDeleteModal extends Component {
  static propTypes = {
    onSubmit: func.isRequired,
    selectedCount: number,
    defaultOpen: bool,
  }

  static defaultProps = {
    defaultOpen: true,
    selectedCount: 1,
  }

  state = {
    open: this.props.defaultOpen,
  }

  UNSAFE_componentWillReceiveProps(props) {
    this.setState({open: props.defaultOpen})
  }

  showDeleteConfirm = () => {
    this.setState({open: true})
  }

  hideDeleteConfirm = () => {
    this.setState({open: false}, () => {
      this.props.onSubmit({isConfirm: false})
    })
  }

  confirmDelete = () => {
    this.setState({open: false}, () => {
      this.props.onSubmit({isConfirm: true})
    })
  }

  render() {
    return (
      <Modal
        open={this.state.open}
        onDismiss={this.hideDeleteConfirm}
        size="small"
        label={I18n.t('Confirm Delete')}
        ref={c => {
          this.confirmDeleteModal = c
        }}
      >
        <Modal.Body>
          {I18n.t(
            {
              one: 'You are about to delete 1 discussion. Are you sure?',
              other: 'You are about to delete %{count} discussions. Are you sure?',
            },
            {count: this.props.selectedCount}
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            ref={c => {
              this.cancelDeleteBtn = c
            }}
            onClick={this.hideDeleteConfirm}
          >
            {I18n.t('Cancel')}
          </Button>
          &nbsp;
          <Button
            ref={c => {
              this.confirmDeleteBtn = c
            }}
            id="confirm_delete_discussions"
            onClick={this.confirmDelete}
            color="danger"
          >
            {I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
