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

import {useScope as createI18nScope} from '@canvas/i18n'
import type {AccountWithCounts} from './types'
import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('sub_accounts')

interface Props {
  account: AccountWithCounts
  onClose: () => void
  onConfirm: () => void
}

export default function DeleteSubaccountModal(props: Props) {
  const [isLoading, setIsLoading] = useState(false)

  return (
    <Modal open={true} label={I18n.t('Delete subaccount confirmation')}>
      <Modal.Header>
        <Heading>{I18n.t('Delete Sub-Account')}</Heading>
        <CloseButton onClick={props.onClose} screenReaderLabel={I18n.t('Close')} placement="end" />
      </Modal.Header>
      <Modal.Body>
        {isLoading ? (
          <View margin="small auto" as="div" textAlign="center">
            <Spinner renderTitle={I18n.t('Deleting subaccount')} />
          </View>
        ) : (
          <Text>{I18n.t("Confirm deleting '%{name}'?", {name: props.account.name})}</Text>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="x-small">
          <Button disabled={isLoading} onClick={props.onClose}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            data-testid="confirm-delete"
            disabled={isLoading}
            onClick={() => {
              setIsLoading(true)
              props.onConfirm()
            }}
            color="danger"
          >
            {I18n.t('Delete')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
