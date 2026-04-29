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
  getRcsToken: () => Promise<string>
  refreshRcsToken: (token: string) => Promise<string>
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
    throw new Error('[AMS Wrapper] Refresh token is required but was undefined')
  }

  // Since refresh endpoint doesn't support unencrypted tokens, get a new one
  return getAccessToken()
}

/**
 * Gets an encrypted service JWT specifically for RCS (Rich Content Service) with 'rich_content' and 'ui' workflows
 */
export const getRcsToken: AuthProps['getRcsToken'] = async () => {
  // Get context from Canvas ENV for JWT request
  const contextType =
    ENV.context_asset_string?.split('_')[0] || ENV.current_context?.type || 'account'
  const contextId =
    ENV.context_asset_string?.split('_')[1] || ENV.current_context?.id || ENV.ACCOUNT_ID
  const url = `/api/v1/jwts?workflows[]=rich_content&workflows[]=ui&context_type=${contextType}&context_id=${contextId}`

  const response = await fetch(url, {
    method: 'POST',
    ...defaultFetchOptions(),
  })

  if (!response.ok) {
    if (response.status === 401) {
      assignLocation('/login/canvas')
      throw new Error('Unauthorized - redirecting to login')
    }
    throw new Error(
      `[AMS Wrapper] Failed to get RCS token: ${response.status} ${response.statusText}`,
    )
  }

  const data = await response.json()
  return data.token
}

/**
 * Refreshes an encrypted service JWT for RCS using Canvas's refresh endpoint
 */
export const refreshRcsToken: AuthProps['refreshRcsToken'] = async (token: string) => {
  if (!token) {
    console.error('[AMS Wrapper] Cannot refresh token: token is undefined')
    throw new Error('[AMS Wrapper] Refresh token is required but was undefined')
  }

  const response = await fetch('/api/v1/jwts/refresh', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...defaultFetchOptions().headers,
    },
    body: JSON.stringify({jwt: token}),
  })

  if (!response.ok) {
    if (response.status === 401) {
      assignLocation('/login/canvas')
      throw new Error('Unauthorized - redirecting to login')
    }
    // If refresh fails, try to get a new RCS token
    console.warn(`[AMS Wrapper] RCS token refresh failed (${response.status}), getting new token`)
    return getRcsToken()
  }

  const data = await response.json()
  return data.token
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
