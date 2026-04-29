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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'

const I18n = createI18nScope('modules')

export interface PreSaveRelockModalProps {
  open: boolean
  onSave: (shouldRelock: boolean) => Promise<void>
  onCancel: () => void
}

export default function PreSaveRelockModal({open, onSave, onCancel}: PreSaveRelockModalProps) {
  const [isSaving, setIsSaving] = useState(false)

  const handleSaveAndRelock = async () => {
    setIsSaving(true)
    await onSave(true)
  }

  const handleSaveWithoutRelock = async () => {
    setIsSaving(true)
    await onSave(false)
  }

  const handleCancel = () => {
    if (!isSaving) {
      onCancel()
    }
  }

  return (
    <Modal
      open={open}
      onDismiss={handleCancel}
      size="small"
      label={I18n.t('Module requirements changed')}
      shouldCloseOnDocumentClick={false}
      data-testid="pre-save-relock-modal"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleCancel}
          screenReaderLabel={I18n.t('Close')}
          disabled={isSaving}
        />
        <Heading>{I18n.t('Module requirements changed')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small 0">
          <Text>
            {I18n.t(
              'Students may have already made progress on this module or on a module that depends on it.',
            )}
          </Text>
        </View>
        <View as="div">
          <List margin="none">
            <List.Item>
              {I18n.t(
                'By re-locking the module, students will lose their progress and start over with your changes.',
              )}
            </List.Item>
            <List.Item>
              {I18n.t(
                "By continuing without re-locking, students won't lose their progress — but it may not reflect your changes.",
              )}
            </List.Item>
          </List>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button
          data-testid="relock-cancel-button"
          onClick={handleCancel}
          margin="0 x-small 0 0"
          disabled={isSaving}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          onClick={handleSaveAndRelock}
          margin="0 x-small 0 0"
          disabled={isSaving}
          interaction={isSaving ? 'disabled' : 'enabled'}
          data-testid="relock-button"
        >
          {I18n.t('Re-lock modules')}
        </Button>
        <Button
          onClick={handleSaveWithoutRelock}
          color="primary"
          disabled={isSaving}
          interaction={isSaving ? 'disabled' : 'enabled'}
          data-testid="continue-without-relock-button"
        >
          {I18n.t('Continue')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
