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

import I18n from 'i18n!confirmMasteryScaleEditModal'
import React, {Component} from 'react'
import {func, string, bool} from 'prop-types'
import {Button} from '@instructure/ui-buttons'

import Modal from '../shared/components/InstuiModal'

export default class ConfirmMasteryScaleEdit extends Component {
  static propTypes = {
    onConfirm: func.isRequired,
    contextType: string.isRequired,
    isOpen: bool.isRequired,
    onClose: func.isRequired
  }

  onConfirm = () => {
    this.props.onConfirm()
  }

  onClose = () => {
    this.props.onClose()
  }

  getModalText = () => {
    const {contextType} = this.props
    if (contextType === 'Course') {
      return I18n.t(
        'This will update all rubrics aligned to outcomes within this course that have not yet been assessed.'
      )
    }
    return I18n.t(
      'This will update all account and course level rubrics that are tied to the account level mastery scale and have not yet been assessed.'
    )
  }

  render() {
    return (
      <Modal
        label={I18n.t('Confirm Mastery Scale')}
        open={this.props.isOpen}
        onDismiss={this.onClose}
        size="small"
      >
        <Modal.Body>
          <div>{this.getModalText()}</div>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.onClose}>{I18n.t('Cancel')}</Button>
          &nbsp;
          <Button onClick={this.onConfirm} variant="primary">
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
