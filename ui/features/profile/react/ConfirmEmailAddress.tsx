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

import React, {type ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {raw} from '@instructure/html-escape'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('profile')

interface ConfirmEmailAddressProps {
  email: string
  children: ReactNode
  onClose: () => void
}

const ConfirmEmailAddress = ({email, children, onClose}: ConfirmEmailAddressProps) => {
  const title = I18n.t('Confirm Email Address')

  return (
    <Modal
      open={true}
      onDismiss={onClose}
      size="small"
      label={title}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="medium" padding="small 0 0 0">
          <Text
            dangerouslySetInnerHTML={{
              __html: raw(
                I18n.t(
                  'We emailed a confirmation link to *%{email}*. Click the link in that email to finish registering. Make sure to check your spam box in case it got filtered.',
                  {wrapper: '<b>$1</b>', email},
                ),
              ),
            }}
          />
          {children}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="submit" color="primary" onClick={onClose}>
          {I18n.t('Ok, Thanks')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default ConfirmEmailAddress
