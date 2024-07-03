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
import {useScope as useI18nScope} from '@canvas/i18n'

import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('discussion_create')

export const SendEditNotificationModal = ({
  onClose,
  submitForm,
}: {
  onClose: () => void
  submitForm: (sendNotification: boolean) => void
}) => {
  return (
    <Modal
      as="form"
      open={true}
      size="small"
      label={I18n.t('Notify Users')}
      data-testid="send-notification-modal"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Notify Users')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text lineHeight="double">
          {I18n.t(
            'Would you like to send a notification to users that the Announcement has been edited?'
          )}
        </Text>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="small">
          <Button data-testid="cancel" onClick={onClose}>
            {I18n.t('Cancel')}
          </Button>
          <Button data-testid="no_send" onClick={() => submitForm(false)}>
            {I18n.t('Save & Don’t Send')}
          </Button>
          <Button data-testid="send" onClick={() => submitForm(true)} color="primary">
            {I18n.t('Send')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
