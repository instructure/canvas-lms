/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_2'

import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Modal, {
  ModalHeader,
  ModalBody
  // ModalFooter
} from '@instructure/ui-overlays/lib/components/Modal'

export default function MessageStudentsWho(props) {
  return (
    <Modal label={I18n.t('Message Students Who')} {...props}>
      <ModalHeader>
        <CloseButton placement="end" variant="icon" onClick={props.onDismiss}>
          {I18n.t('Close')}
        </CloseButton>
      </ModalHeader>
      <ModalBody>
        <div data-testid="message-students-who">Message Students Who</div>
      </ModalBody>
    </Modal>
  )
}
