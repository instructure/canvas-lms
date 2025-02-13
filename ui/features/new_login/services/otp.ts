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
import type {ApiResponse, OtpInitiationResponse, OtpVerifyResponse} from '../types'

export const initiateOtpRequest = async (): Promise<ApiResponse<OtpInitiationResponse>> => {
  const {json, response} = await doFetchApi<OtpInitiationResponse>({
    path: '/login/otp',
    method: 'GET',
  })

  return {status: response.status, data: json ?? ({} as OtpInitiationResponse)}
}

export const verifyOtpRequest = async (
  verificationCode: string,
  rememberMe: boolean,
  csrfToken?: string,
): Promise<ApiResponse<OtpVerifyResponse>> => {
  const token = csrfToken || authenticityToken()
  const {json, response} = await doFetchApi<OtpVerifyResponse>({
    path: '/login/otp',
    method: 'POST',
    body: {
      authenticity_token: token,
      otp_login: {
        verification_code: verificationCode,
        remember_me: rememberMe ? '1' : '0',
      },
    },
  })

  return {status: response.status, data: json ?? ({} as OtpVerifyResponse)}
}

export const cancelOtpRequest = async (csrfToken?: string) => {
  const token = csrfToken || authenticityToken()
  const {json, response} = await doFetchApi({
    path: '/login/otp/cancel',
    method: 'DELETE',
    body: {
      authenticity_token: token,
    },
  })

  return {status: response.status, data: json ?? {}}
}
