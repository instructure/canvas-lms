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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useCallback} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('horizon_toggle_page')

export interface RevertAccountProps {
  accountId: string
  isHorizonAccountLocked: boolean
}

export const RevertAccount = ({accountId, isHorizonAccountLocked}: RevertAccountProps) => {
  const onSubmit = useCallback(async () => {
    try {
      await doFetchApi({
        path: `/api/v1/accounts/${accountId}`,
        method: 'PUT',
        body: {
          id: accountId,
          account: {settings: {horizon_account: {value: false}}},
        },
      })

      window.location.reload()
    } catch (e) {
      showFlashError(I18n.t('Failed to revert sub-account. Please try again.'))
    }
  }, [accountId])

  return (
    <View as="div">
      <Flex gap="large" margin="large 0 0 0" direction="column">
        <View>
          <Heading level="h3">{I18n.t('Revert Sub Account')}</Heading>
          <Text as="p">
            {I18n.t(
              'By reverting, all Canvas Career features will be disabled. Reverting will result in the loss of features, including the simplified user interface along with, program management, AI-driven actionable insights, and more! These features will no longer be available after the sub account is reverted.',
            )}
          </Text>
        </View>
        <Flex justifyItems="end">
          <Button color="primary" onClick={onSubmit} disabled={isHorizonAccountLocked}>
            {I18n.t('Revert Sub Account')}
          </Button>
        </Flex>
      </Flex>
    </View>
  )
}
