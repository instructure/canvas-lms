/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import authenticityToken from '@canvas/authenticity-token'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ApiResponse, LoginResponse} from '../types'

export const performSignIn = async (
  username: string,
  password: string,
  rememberMe: boolean,
  route: string,
  csrfToken?: string,
): Promise<ApiResponse<LoginResponse>> => {
  const token = csrfToken || authenticityToken()
  const {json, response} = await doFetchApi<LoginResponse>({
    path: route,
    method: 'POST',
    body: {
      authenticity_token: token,
      pseudonym_session: {
        unique_id: username,
        password,
        remember_me: rememberMe ? '1' : '0',
      },
    },
  })

  return {status: response.status, data: json ?? ({} as LoginResponse)}
}

export const forgotPassword = async (
  email: string,
  csrfToken?: string,
): Promise<ApiResponse<{requested: boolean}>> => {
  const token = csrfToken || authenticityToken()
  const {json, response} = await doFetchApi<{requested: boolean}>({
    path: '/forgot_password',
    method: 'POST',
    body: {
      authenticity_token: token,
      pseudonym_session: {
        unique_id_forgot: email,
      },
    },
  })

  return {status: response.status, data: json ?? {requested: false}}
}
