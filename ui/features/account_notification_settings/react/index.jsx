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

import {ApolloProvider, createClient} from '@canvas/apollo'
import React from 'react'
import AccountNotificationSettingsView from './AccountNotificationSettingsView'

export default function NotificationSettings(options = {}) {
  const apolloClientOpts = {}
  const envDict = options.envDict || ENV
  const client = createClient(apolloClientOpts)
  return (
    <ApolloProvider client={client}>
      <AccountNotificationSettingsView
        accountId={envDict.DOMAIN_ROOT_ACCOUNT_ID}
        userId={envDict.current_user_id}
      />
    </ApolloProvider>
  )
}
