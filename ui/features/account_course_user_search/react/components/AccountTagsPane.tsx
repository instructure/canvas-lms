/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React from 'react'
import {AccountTags} from '@instructure/platform-institutional-tagging'
import {PlatformUiProvider, type Account} from '@instructure/platform-provider'
import {platformExecuteQuery} from '@canvas/graphql'
import {queryClient} from '@canvas/query'

interface AccountWithPermissions extends Account {
  permissions: {
    canView: boolean | undefined
    canCreate: boolean | undefined
    canEdit: boolean | undefined
  }
}

const AccountTagsPane = () => {
  const account: AccountWithPermissions = {
    id: String(ENV.ROOT_ACCOUNT_ID),
    name: '',
    executeQuery: platformExecuteQuery,
    currentUserId: ENV.current_user_id ?? '',
    locale: ENV.LOCALE ?? 'en',
    timezone: ENV.TIMEZONE ?? 'UTC',
    permissions: {
      canView: ENV.PERMISSIONS?.can_view_institutional_tags,
      canCreate: ENV.PERMISSIONS?.can_create_institutional_tags,
      canEdit: ENV.PERMISSIONS?.can_edit_institutional_tags,
    },
  }

  return (
    <PlatformUiProvider accounts={[account as Account]} queryClient={queryClient}>
      <AccountTags />
    </PlatformUiProvider>
  )
}

export default AccountTagsPane
