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
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

const I18n = useI18nScope('account_grading_status')

declare const ENV: GlobalEnv & {
  IS_ROOT_ACCOUNT: boolean
  ROOT_ACCOUNT_ID: string
}

export function Component() {
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
        isRootAccount={Boolean(ENV.IS_ROOT_ACCOUNT)}
        rootAccountId={ENV.ROOT_ACCOUNT_ID}
        isExtendedStatusEnabled={ENV.FEATURES.extended_submission_state}
      />
    </ApolloProvider>
  )
}
