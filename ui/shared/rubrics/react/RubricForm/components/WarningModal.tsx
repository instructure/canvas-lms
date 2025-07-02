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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('rubrics-form')

type WarningModalProps = {
  isOpen: boolean
  onDismiss: () => void
  onCancel: () => void
}

export function WarningModal({isOpen, onCancel, onDismiss}: WarningModalProps) {
  const modalHeader = I18n.t('Warning')
  const message = I18n.t(
    'You are about to exit the rubric editor. Any unsaved changes will be lost.',
  )
  const exitButtonText = I18n.t('Exit')
  const cancelButtonText = I18n.t('Cancel')

  const handleExit = () => {
    onDismiss()
    onCancel()
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={modalHeader}
      shouldCloseOnDocumentClick={false}
      overflow="scroll"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading data-testid="rubric-assignment-exit-warning-modal">{modalHeader}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" width="80%" margin="0 auto">
          {message}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="cancel-rubric-warning-button" onClick={onDismiss}>
          {cancelButtonText}
        </Button>
        &nbsp;
        <Button
          data-testid="exit-rubric-warning-button"
          onClick={handleExit}
          color="primary"
          type="submit"
        >
          {exitButtonText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
