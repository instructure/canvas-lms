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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {useQuery} from '@canvas/query'
import SubaccountTree from './SubaccountTree'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AccountWithCounts} from './types'
import {Heading} from '@instructure/ui-heading'
import {useParams} from 'react-router-dom'
import {Portal} from '@instructure/ui-portal'
import {FocusProvider} from './util'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('sub_accounts')

interface Props {
  rootAccountId: string
}

const fetchRootAccount = async (id: string): Promise<AccountWithCounts> => {
  const params = {
    includes: ['course_count', 'sub_account_count'],
  }
  const {json} = await doFetchApi({
    path: `/api/v1/accounts/${id}`,
    method: 'GET',
    params,
  })
  return json as AccountWithCounts
}

export default function SubaccountRoute(props: Props) {
  const {data, isLoading, error} = useQuery({
    queryKey: ['account', props.rootAccountId],
    queryFn: () => fetchRootAccount(props.rootAccountId),
  })

  const renderTree = () => {
    if (error) {
      return <Alert variant="error">{I18n.t('Failed loading subaccounts')}</Alert>
    } else if (isLoading || !data) {
      return <Spinner renderTitle={I18n.t('Loading subaccounts')} />
    }
    return <SubaccountTree isTopAccount={true} rootAccount={data} indent={1} />
  }

  return <FocusProvider accountId={props.rootAccountId}>{renderTree()}</FocusProvider>
}

export function Component(): JSX.Element | null {
  const params = useParams()
  const mountPoint = document.getElementById('sub_account_mount')

  if (!mountPoint) {
    return null
  }
  return (
    <Portal key={mountPoint.id} open={true} mountNode={mountPoint}>
      <Flex margin="small" gap="medium" direction="column">
        <Heading level="h2" as="h1">
          {I18n.t('Sub-Accounts')}
        </Heading>
        <SubaccountRoute rootAccountId={params.accountId!} />
      </Flex>
    </Portal>
  )
}
