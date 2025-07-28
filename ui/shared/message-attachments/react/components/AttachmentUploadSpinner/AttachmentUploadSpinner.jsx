/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('conversations_2')

export const AttachmentUploadSpinner = props => {
  const {
    label = I18n.t('Uploading Files'),
    message = I18n.t('Please wait while we upload attachments.'),
    sendMessage,
    isMessageSending,
    pendingUploads,
  } = props
  return (
    <Modal
      open={isMessageSending && !!pendingUploads.length}
      label={label}
      shouldCloseOnDocumentClick={false}
      onExited={() => sendMessage()}
    >
      <Modal.Body>
        <Flex direction="column" textAlign="center">
          <Flex.Item>
            <Spinner renderTitle={label} size="large" />
          </Flex.Item>
          <Flex.Item>
            <Text>{message}</Text>
          </Flex.Item>
        </Flex>
      </Modal.Body>
    </Modal>
  )
}

export default AttachmentUploadSpinner

AttachmentUploadSpinner.propTypes = {
  label: PropTypes.string,
  message: PropTypes.string,
  sendMessage: PropTypes.func.isRequired,
  isMessageSending: PropTypes.bool.isRequired,
  pendingUploads: PropTypes.array.isRequired,
}
