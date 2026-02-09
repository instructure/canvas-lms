/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Button, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {IconXSolid} from '@instructure/ui-icons'
interface UnsavedChangesModalProps {
  isOpen: boolean
  onConfirm: () => void
  onCancel: () => void
  onClose: () => void
}
const I18n = createI18nScope('accessibility_checker')
const UnsavedChangesModal: React.FC<UnsavedChangesModalProps> = ({
  isOpen,
  onConfirm,
  onClose,
  onCancel,
}) => {
  return (
    <Modal
      open={isOpen}
      onDismiss={onCancel}
      size="small"
      data-testid="unsaved-changes-modal"
      label="Unsaved Changes Confirmation"
    >
      <Modal.Header>
        <Flex width="100%" justifyItems="space-between">
          <Heading level="h3">{I18n.t('You have unsaved changes')}</Heading>
          <IconButton
            size="small"
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Close')}
            onClick={onClose}
            data-testid="modal-close-button"
          >
            <IconXSolid />
          </IconButton>
        </Flex>
      </Modal.Header>
      <Modal.Body>
        <Text>{I18n.t('Some of the fixes that you made are not saved.')}</Text>
        <br />
        <Text>{I18n.t('Do you want to proceed without saving?')}</Text>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="small" justifyItems="end">
          <Flex.Item>
            <Button onClick={onCancel}>{I18n.t("Don't save")}</Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="primary" onClick={onConfirm}>
              {I18n.t('Save changes')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
export default UnsavedChangesModal
