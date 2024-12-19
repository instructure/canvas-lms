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
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('rubrics-assessment-tray')

type LongDescriptionModalProps = {
  open: boolean
  onClose: () => void
  longDescription: string
}
export const LongDescriptionModal = ({
  open,
  onClose,
  longDescription,
}: LongDescriptionModalProps) => {
  const modalHeader = I18n.t('Criterion Long Description')
  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="medium"
      label={modalHeader}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{modalHeader}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text lineHeight="double" wrap="break-word">
          <div dangerouslySetInnerHTML={{__html: longDescription}} />
        </Text>
      </Modal.Body>
    </Modal>
  )
}
