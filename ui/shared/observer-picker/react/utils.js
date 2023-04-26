/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import natcompare from '@canvas/util/natcompare'
import doFetchApi from '@canvas/do-fetch-api-effect'

export const parseObservedUsersList = users =>
  users
    ? users.map(u => ({
        id: u.id,
        name: u.name,
        avatarUrl: u.avatar_url,
      }))
    : []

export const parseObservedUsersResponse = (enrollments, isOnlyObserver, currentUser) => {
  const users = enrollments
    .filter(e => e.observed_user)
    .reduce((acc, e) => {
      if (!acc.some(user => user.id === e.observed_user.id)) {
        acc.push({
          id: e.observed_user.id,
          name: e.observed_user.name,
          sortableName: e.observed_user.sortable_name,
          avatarUrl: e.observed_user.avatar_url,
        })
      }
      return acc
    }, [])
    .sort((a, b) => natcompare.strings(a.sortableName, b.sortableName))
  if (!isOnlyObserver) {
    users.unshift({
      id: currentUser.id,
      name: currentUser.display_name,
      avatarUrl: currentUser.avatar_image_url,
    })
  }
  return users
}

export const fetchShowK5Dashboard = () =>
  doFetchApi({path: `/api/v1/show_k5_dashboard`}).then(({json}) => json)
