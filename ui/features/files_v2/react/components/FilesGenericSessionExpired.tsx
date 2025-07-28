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
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import {Modal, ModalBody, ModalFooter, ModalHeader} from '@instructure/ui-modal'

const I18n = createI18nScope('files_v2')

export const FilesGenericSessionExpired = ({
  isOpen,
  onClose,
}: {
  isOpen: boolean
  onClose: () => void
}) => {
  const onClick = () => {
    onClose()
    window.location.href = '/login'
  }

  return (
    <Modal open={isOpen} onDismiss={onClose} label={I18n.t('Session expired')} size="small">
      <ModalHeader>
        <Heading level="h2">{I18n.t('Your session has expired')}</Heading>
      </ModalHeader>
      <ModalBody>
        {I18n.t(
          'For security reasons your session has timed out. Please log in again to continue where you left off.',
        )}
      </ModalBody>
      <ModalFooter>
        <Button color="primary" onClick={onClick}>
          {I18n.t('Go to login')}
        </Button>
      </ModalFooter>
    </Modal>
  )
}
