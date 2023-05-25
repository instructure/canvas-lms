// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendar_settings_confirmation_modal')

export interface ComponentProps {
  readonly isOpen: boolean
  readonly onCancel: () => void
  readonly onConfirm: () => void
}

const ConfirmationModal: React.FC<ComponentProps> = ({isOpen, onCancel, onConfirm}) => {
  const title = I18n.t('Apply Changes')
  return (
    <Modal
      open={isOpen}
      onDismiss={onCancel}
      size="small"
      label={title}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          data-testid="x-close-button"
          onClick={onCancel}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div">
          <Text as="p">
            {I18n.t(
              'All new and existing users in the sub-account will be auto-subscribed to selected calendars.'
            )}
          </Text>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="close-button" onClick={onCancel} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button data-testid="confirm-button" onClick={onConfirm} color="primary">
          {I18n.t('Confirm')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default ConfirmationModal
