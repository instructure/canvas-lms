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
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_insights')

type ReviewModalProps = {
  isOpen: boolean
  onClose: () => void
}

const ReviewModal: React.FC<ReviewModalProps> = ({isOpen, onClose}) => {
  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={onClose}
      size="auto"
      label={I18n.t('Review Evaluation')}
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Review Evaluation')}</Heading>
      </Modal.Header>
      <Modal.Body></Modal.Body>
    </Modal>
  )
}

export default ReviewModal
