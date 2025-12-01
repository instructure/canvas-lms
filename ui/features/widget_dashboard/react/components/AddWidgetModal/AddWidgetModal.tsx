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
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('widget_dashboard')

interface AddWidgetModalProps {
  open: boolean
  onClose: () => void
  targetColumn: number
  targetRow: number
}

const AddWidgetModal: React.FC<AddWidgetModalProps> = ({
  open,
  onClose,
  targetColumn,
  targetRow,
}) => {
  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="large"
      label={I18n.t('Add widget')}
      data-testid="add-widget-modal"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
          data-testid="close-button"
        />
        <Heading data-testid="modal-heading">{I18n.t('Add widget')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <div>Modal content coming soon...</div>
      </Modal.Body>
    </Modal>
  )
}

export default AddWidgetModal
