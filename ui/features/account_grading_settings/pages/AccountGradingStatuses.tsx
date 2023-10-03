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

import React, {useEffect, useState} from 'react'
import {useMatch} from 'react-router-dom'
import {ApolloProvider, createClient} from '@canvas/apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {AccountStatusManagement} from '../components/account_grading_status/AccountStatusManagement'

const I18n = useI18nScope('account_grading_status')

type AccountGradingStatusesProps = {
  isRootAccount: boolean
  rootAccountId: string
  isExtendedStatusEnabled?: boolean
}
export const AccountGradingStatuses = ({
  isRootAccount,
  rootAccountId,
  isExtendedStatusEnabled,
}: AccountGradingStatusesProps) => {
  const pathMatch = useMatch('/accounts/:accountId/*')
  const accountId = pathMatch?.params?.accountId
  if (!accountId) {
    throw new Error('account id is not present on path')
  }

  const [client, setClient] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    document.title = I18n.t('Account Custom Statuses')
    setClient(createClient())
    setLoading(false)
  }, [])

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <ApolloProvider client={client}>
      <AccountStatusManagement
        isRootAccount={isRootAccount}
        rootAccountId={rootAccountId}
        isExtendedStatusEnabled={isExtendedStatusEnabled}
      />
    </ApolloProvider>
  )
}
