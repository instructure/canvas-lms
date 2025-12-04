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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('ai_experiences_edit')

interface PreviewConfirmationModalProps {
  open: boolean
  onDismiss: () => void
  onConfirm: () => void
}

const PreviewConfirmationModal: React.FC<PreviewConfirmationModalProps> = ({
  open,
  onDismiss,
  onConfirm,
}) => {
  return (
    <Modal
      open={open}
      onDismiss={onDismiss}
      size="small"
      label={I18n.t('Preview AI experience')}
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <CloseButton
          data-testid="ai-experience-edit-preview-close-preview-confirmation-button"
          placement="end"
          offset="small"
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Preview AI experience')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text>
          {I18n.t(
            'We will save this experience as a draft so you can preview it. Please confirm to proceed.',
          )}
        </Text>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item padding="0 x-small 0 0">
            <Button
              data-testid="ai-experience-edit-cancel-preview-confirmation-button"
              onClick={onDismiss}
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              data-testid="ai-experience-edit-confirm-preview-confirmation-button"
              onClick={onConfirm}
              color="primary"
            >
              {I18n.t('Confirm')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default PreviewConfirmationModal
