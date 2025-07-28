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

import {Portal} from '@instructure/ui-portal'
import MergeUsers from './MergeUsers'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

export function Component() {
  const mountPoint = document.getElementById('admin_merge_mount_point')

  if (!mountPoint) {
    return null
  }

  const accountSelectOptions = ENV.ADMIN_MERGE_ACCOUNT_OPTIONS ?? []
  const currentUserId = ENV.current_user.id

  return (
    <Portal open={true} mountNode={mountPoint}>
      <QueryClientProvider client={queryClient}>
        <MergeUsers accountSelectOptions={accountSelectOptions} currentUserId={currentUserId} />
      </QueryClientProvider>
    </Portal>
  )
}
