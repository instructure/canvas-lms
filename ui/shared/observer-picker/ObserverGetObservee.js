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

import getCookie from '@instructure/get-cookie'

// cookie name prefixed with k5_ for historical reasons but not exclusively used in k5 mode
export const OBSERVER_COOKIE_PREFIX = 'k5_observed_user_for_'

export const savedObservedCookieName = currentUserId => `${OBSERVER_COOKIE_PREFIX}${currentUserId}`

export const savedObservedId = currentUserId => getCookie(savedObservedCookieName(currentUserId))

export const saveObservedId = (currentUserId, observeeId) => {
  document.cookie = observedCookie(currentUserId, observeeId)
}

export const clearObservedId = currentUserId => {
  document.cookie = `${observedCookie(currentUserId, '')};max-age=-1`
}

const observedCookie = (currentUserId, observeeId) =>
  `${savedObservedCookieName(currentUserId)}=${observeeId};path=/`
