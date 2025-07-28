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

const I18n = createI18nScope('enhanced-rubrics-delete-modal')

type DeleteConfirmModalProps = {
  associationCount: number
  isOpen: boolean
  onConfirm: () => void
  onDismiss: () => void
}
export const DeleteConfirmModal = ({
  associationCount,
  isOpen,
  onConfirm,
  onDismiss,
}: DeleteConfirmModalProps) => {
  const hasMultipleAssociations = associationCount > 1
  const title = hasMultipleAssociations ? I18n.t('Unlink Rubric') : I18n.t('Delete Rubric?')
  const deleteText = hasMultipleAssociations
    ? I18n.t(
        'The rubric is associated with another assignment. You can remove this rubric from the assignment without impacting other assignments by unlinking it',
      )
    : I18n.t('You are about to permanently delete this rubric. Do you wish to proceed?')

  return (
    <Modal
      data-testid="delete-confirm-modal"
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={title}
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
      <Modal.Body>{deleteText}</Modal.Body>
      <Modal.Footer>
        <Button data-testid="delete-cancel-btn" onClick={onDismiss} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        {hasMultipleAssociations ? (
          <Button data-testid="delete-confirm-btn" color="primary" onClick={onConfirm}>
            {I18n.t('Unlink')}
          </Button>
        ) : (
          <Button data-testid="delete-confirm-btn" color="danger" onClick={onConfirm}>
            {I18n.t('Delete')}
          </Button>
        )}
      </Modal.Footer>
    </Modal>
  )
}
