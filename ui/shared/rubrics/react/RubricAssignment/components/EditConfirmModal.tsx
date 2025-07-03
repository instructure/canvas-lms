/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

const I18n = createI18nScope('enhanced-rubrics-copy-edit-modal')

type EditConfirmModalProps = {
  isOpen: boolean
  onConfirm: () => void
  onDismiss: () => void
}
export const EditConfirmModal = ({isOpen, onConfirm, onDismiss}: EditConfirmModalProps) => {
  const warningText = I18n.t(
    'This rubric has already been used for grading. Saving changes may alter student scores or grading history. Are you sure you want to proceed?',
  )

  return (
    <Modal
      data-testid="edit-confirm-modal"
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={I18n.t('Edit Confirm Modal')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading level="h3">{I18n.t('Confirm to continue')}</Heading>
      </Modal.Header>
      <Modal.Body>{warningText}</Modal.Body>
      <Modal.Footer>
        <Button data-testid="edit-cancel-btn" onClick={onDismiss} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button data-testid="edit-confirm-btn" color="primary" onClick={onConfirm}>
          {I18n.t('Confirm')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
