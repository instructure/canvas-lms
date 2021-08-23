/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import AlertManager from '@canvas/alerts/react/AlertManager'
import {ApolloProvider, createClient} from '@canvas/apollo'
import AccountNotificationSettingsQuery from './AccountNotificationSettingsQuery'
import React from 'react'

export default function NotificationSettings(options = {}) {
  const apolloClientOpts = {}
  const envDict = options.envDict || ENV
  if (envDict.API_GATEWAY_URI) {
    apolloClientOpts.apiGatewayUri = envDict.API_GATEWAY_URI
  }
  const client = createClient(apolloClientOpts)
  return (
    <ApolloProvider client={client}>
      <AlertManager>
        <AccountNotificationSettingsQuery
          accountId={envDict.DOMAIN_ROOT_ACCOUNT_ID}
          userId={envDict.current_user_id}
        />
      </AlertManager>
    </ApolloProvider>
  )
}
