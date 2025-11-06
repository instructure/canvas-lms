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

import {defaultFetchOptions} from '@canvas/util/xhr'
import {assignLocation} from '@canvas/util/globalUtils'

type TokenResponse = {
  accessToken: string | null
  refreshToken: string | null
}

type Context = {
  id: string
  name: string
  type: string
  url: string
}

export type User = {
  name: string
  id: string
  roles: string[]
  isStudent: boolean
  context: Context
}

export type AuthProps = {
  getAccessToken: () => Promise<TokenResponse>
  refreshToken: (refreshToken?: string | null) => Promise<TokenResponse>
  getUser: () => Promise<User | null>
}

export const getAccessToken: AuthProps['getAccessToken'] = async () => {
  const token = await fetch(`/api/v1/jwts?canvas_audience=false`, {
    method: 'POST',
    ...defaultFetchOptions(),
  })
    .then(resp => {
      if (resp.status === 401) {
        assignLocation('/login/canvas')
        throw new Error('Unauthorized - redirecting to login')
      }
      return resp.json()
    })
    .then(data => data.token)
    .then(token => atob(token)) // remove extra encoding carried by this JWT
  // uncomment for debugging
  // console.debug('Access token:', token)
  // console.debug('Decoded access token:', Buffer.from(token, 'base64').toString('utf8'))

  // Using same token for both access and refresh see JwtsController#refresh
  return {accessToken: token, refreshToken: token}
}

/**
 * `/api/v1/jwts/refresh` (JwtsController#refresh) does not support refreshing
 * unencrypted tokens(when canvas_audience=false).
 *
 * CURRENT APPROACH: Since refresh is not supported, we simply request a new
 * token via getAccessToken().
 *
 * TODO: Anyway, this is a temporary implementation. Eventually, we should migrate to
 * a proper Identity Service that supports standard JWT flows.
 *
 *
 */
export const refreshToken: AuthProps['refreshToken'] = async token => {
  if (!token) {
    console.error('[AMS Wrapper] Cannot refresh token: token is undefined')
    return Promise.reject(new Error('[AMS Wrapper] Refresh token is required but was undefined'))
  }

  // Since refresh endpoint doesn't support unencrypted tokens, get a new one
  return getAccessToken()
}

export const getUser: AuthProps['getUser'] = async () => {
  if (!ENV.current_user_id) {
    throw new Error('[AMS Wrapper] User not authenticated: current_user_id is missing from ENV')
  }

  return {
    id: ENV.current_user_id,
    name: ENV.current_user?.display_name,
    roles: ENV.current_user_roles,
    isStudent: ENV.current_user_is_student,
    context: ENV.current_context as Context,
  }
}
