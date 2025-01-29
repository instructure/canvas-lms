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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import type {Rubric} from '../../types/rubric'

const I18n = createI18nScope('enhanced-rubrics-copy-edit-modal')

type CopyEditConfirmModalProps = {
  accountMasterScalesEnabled: boolean
  contextAssetString: string
  isOpen: boolean
  onConfirm: () => void
  onDismiss: () => void
  rubric?: Rubric
}
export const CopyEditConfirmModal = ({
  accountMasterScalesEnabled,
  contextAssetString,
  isOpen,
  onConfirm,
  onDismiss,
  rubric,
}: CopyEditConfirmModalProps) => {
  const getCopyEditText = () => {
    if (!shouldUseMasteryScale()) {
      return I18n.t(
        "You can't edit this " +
          "rubric, either because you don't have permission " +
          "or it's being used in more than one place. Any " +
          'changes you make will result in a new rubric based on the old rubric. Continue anyway?',
      )
    }
    if (contextAssetString.includes('course')) {
      return I18n.t(
        "You can't edit this " +
          "rubric, either because you don't have permission " +
          "or it's being used in more than one place. Any " +
          'changes you make will result in a new rubric. Any associated outcome criteria will use the course mastery scale. Continue anyway?',
      )
    } else {
      return I18n.t(
        "You can't edit this " +
          "rubric, either because you don't have permission " +
          "or it's being used in more than one place. Any " +
          'changes you make will result in a new rubric. Any associated outcome criteria will use the account mastery scale. Continue anyway?',
      )
    }
  }

  const shouldUseMasteryScale = () => {
    if (!accountMasterScalesEnabled || !rubric) {
      return false
    }
    return rubric.criteria?.some(criterion => criterion.learningOutcomeId)
  }

  return (
    <Modal
      data-testid="copy-edit-confirm-modal"
      open={isOpen}
      onDismiss={onDismiss}
      size="small"
      label={I18n.t('Copy/Edit Confirm Modal')}
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
      <Modal.Body>{getCopyEditText()}</Modal.Body>
      <Modal.Footer>
        <Button data-testid="copy-edit-cancel-btn" onClick={onDismiss} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button data-testid="copy-edit-confirm-btn" color="primary" onClick={onConfirm}>
          {I18n.t('Confirm')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
