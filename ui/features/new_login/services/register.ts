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
import type {ApiResponse, RegistrationResponse} from '../types'

export const createTeacherAccount = async (payload: {
  name: string
  email: string
  termsAccepted: boolean
  captchaToken?: string
  csrfToken?: string
}): Promise<ApiResponse<RegistrationResponse>> => {
  const token = payload.csrfToken || authenticityToken()
  const {json, response} = await doFetchApi<RegistrationResponse>({
    path: '/users',
    method: 'POST',
    body: {
      authenticity_token: token,
      user: {
        initial_enrollment_type: 'teacher',
        name: payload.name,
        terms_of_use: payload.termsAccepted ? '1' : '0',
      },
      pseudonym: {
        unique_id: payload.email,
      },
      'g-recaptcha-response': payload.captchaToken,
    },
  })

  return {status: response.status, data: json ?? {success: false}}
}

export const createParentAccount = async (payload: {
  name: string
  email: string
  password: string
  confirmPassword: string
  pairingCode: string
  termsAccepted: boolean
  captchaToken?: string
  csrfToken?: string
}): Promise<ApiResponse<RegistrationResponse>> => {
  const token = payload.csrfToken || authenticityToken()
  const {json, response} = await doFetchApi<RegistrationResponse>({
    path: '/users',
    method: 'POST',
    body: {
      authenticity_token: token,
      user: {
        initial_enrollment_type: 'observer',
        name: payload.name,
        skip_registration: '1',
        terms_of_use: payload.termsAccepted ? '1' : '0',
      },
      pseudonym: {
        password: payload.password,
        password_confirmation: payload.confirmPassword,
        unique_id: payload.email,
      },
      pairing_code: {
        code: payload.pairingCode,
      },
      communication_channel: {
        skip_confirmation: '1',
      },
      'g-recaptcha-response': payload.captchaToken,
    },
  })

  return {status: response.status, data: json ?? {success: false}}
}

export const createStudentAccount = async (payload: {
  name: string
  username: string
  password: string
  confirmPassword: string
  joinCode: string
  email?: string
  termsAccepted: boolean
  captchaToken?: string
  csrfToken?: string
}): Promise<ApiResponse<RegistrationResponse>> => {
  const token = payload.csrfToken || authenticityToken()
  const {json, response} = await doFetchApi<RegistrationResponse>({
    path: '/users',
    method: 'POST',
    body: {
      authenticity_token: token,
      user: {
        initial_enrollment_type: 'student',
        name: payload.name,
        self_enrollment_code: payload.joinCode,
        terms_of_use: payload.termsAccepted ? '1' : '0',
      },
      pseudonym: {
        password: payload.password,
        password_confirmation: payload.confirmPassword,
        ...(payload.email && {path: payload.email}),
        unique_id: payload.username,
      },
      self_enrollment: '1',
      pseudonym_type: 'username',
      'g-recaptcha-response': payload.captchaToken,
    },
  })

  return {status: response.status, data: json ?? {success: false}}
}
