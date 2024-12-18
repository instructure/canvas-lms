/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('SIS_Import')

export function BatchImportAlert({margin}) {
  return (
    <Alert variant="warning" margin={margin}>
      <p>
        {I18n.t(
          `If selected, this will delete everything for this term, which includes all courses and enrollments
                that are not in the selected import file above. See the documentation for details.`
        )}
      </p>
    </Alert>
  )
}

export function ConfirmationModal({isOpen, onSubmit, onRequestClose}) {
  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={onRequestClose}
      size="small"
      label={I18n.t('Confirm SIS Import Changes')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onRequestClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Confirm Changes')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <BatchImportAlert margin="small" />
        <div>{I18n.t('Please confirm you want to move forward with these changes.')}</div>
      </Modal.Body>
      <Modal.Footer>
        <Button id="confirmation_modal_cancel" onClick={onRequestClose} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button id="confirmation_modal_confirm" color="primary" onClick={onSubmit}>
          {I18n.t('Confirm')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export function renderBatchImportAlert(margin) {
  // eslint-disable-next-line no-restricted-properties
  ReactDOM.render(
    <BatchImportAlert margin={margin} />,
    document.getElementById('batch_import_instructions')
  )
}

export function openModal(onSubmit, onRequestClose) {
  // eslint-disable-next-line no-restricted-properties
  ReactDOM.render(
    <ConfirmationModal isOpen={true} onSubmit={onSubmit} onRequestClose={onRequestClose} />,
    document.getElementById('confirmation_modal_root')
  )
}
