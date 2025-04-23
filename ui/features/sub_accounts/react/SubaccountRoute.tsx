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

import {useQuery} from '@tanstack/react-query'
import SubaccountTree from './SubaccountTree'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {useParams} from 'react-router-dom'
import {Portal} from '@instructure/ui-portal'
import {calculateIndent, fetchRootAccount} from './util'
import {Flex} from '@instructure/ui-flex'
import {AccountWithCounts} from './types'

const I18n = createI18nScope('sub_accounts')

export function Component(): JSX.Element | null {
  const {accountId} = useParams()
  const mountPoint = document.getElementById('sub_account_mount')

  const {error, isLoading, data} = useQuery<AccountWithCounts>({
    queryKey: ['account', accountId],
    queryFn: ({queryKey}) => fetchRootAccount(queryKey[1] as string),
  })

  const renderTree = () => {
    if (error) {
      return <Alert variant="error">{I18n.t('Failed loading subaccounts')}</Alert>
    } else if (isLoading || !data) {
      return (
        <Flex>
          <Flex.Item width={`${calculateIndent(2)}%`} />
          <Spinner size="medium" renderTitle={I18n.t('Loading subaccounts')} />
        </Flex>
      )
    }
    return <SubaccountTree rootAccount={data} depth={1} defaultExpanded={true} />
  }

  if (!mountPoint) {
    return null
  }
  return (
    <Portal key={mountPoint.id} open={true} mountNode={mountPoint}>
      <Flex margin="small" gap="medium" direction="column">
        <Heading level="h2" as="h1">
          {I18n.t('Sub-Accounts')}
        </Heading>
        {renderTree()}
      </Flex>
    </Portal>
  )
}
