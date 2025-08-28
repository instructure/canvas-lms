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

import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'

type ObservedUser = {id: string; name: string; avatar_url?: string | null}

export const getObservedUserId = (
  observedUsersList: ObservedUser[] = ENV.OBSERVED_USERS_LIST ?? [],
  currentUserId: string | undefined = ENV.current_user?.id,
) => {
  const currentObservedId = savedObservedId(currentUserId)

  if (currentObservedId && observedUsersList.some(o => o.id === currentObservedId)) {
    return currentObservedId
  }

  return undefined
}

export const isUserObservingStudent = (
  observedUserId = getObservedUserId(),
  currentUserRoles: string[] | undefined = ENV.current_user_roles,
  currentUserId: string | undefined = ENV.current_user?.id,
) => {
  const isObserver = currentUserRoles?.includes('observer')
  if (!isObserver || !observedUserId) return false

  return currentUserId !== observedUserId
}
