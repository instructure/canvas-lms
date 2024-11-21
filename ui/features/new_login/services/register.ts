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

import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ApiResponse, RegistrationResponse} from '../types'

export const createTeacherAccount = async (
  name: string,
  email: string,
  termsAccepted?: boolean
): Promise<ApiResponse<RegistrationResponse>> => {
  const {json, response} = await doFetchApi<RegistrationResponse>({
    path: '/users',
    method: 'POST',
    body: {
      user: {
        name,
        terms_of_use: termsAccepted ? '1' : '0',
      },
      pseudonym: {
        unique_id: email,
      },
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
}): Promise<ApiResponse<RegistrationResponse>> => {
  const {json, response} = await doFetchApi<RegistrationResponse>({
    path: '/users',
    method: 'POST',
    body: {
      user: {
        name: payload.name,
        terms_of_use: payload.termsAccepted ? '1' : '0',
        initial_enrollment_type: 'observer',
        skip_registration: '1',
      },
      pseudonym: {
        unique_id: payload.email,
        password: payload.password,
        password_confirmation: payload.confirmPassword,
      },
      pairing_code: {
        code: payload.pairingCode,
      },
      communication_channel: {
        skip_confirmation: '1',
      },
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
}): Promise<ApiResponse<RegistrationResponse>> => {
  const {json, response} = await doFetchApi<RegistrationResponse>({
    path: '/users',
    method: 'POST',
    body: {
      user: {
        self_enrollment_code: payload.joinCode,
        name: payload.name,
        terms_of_use: payload.termsAccepted ? '1' : '0',
        initial_enrollment_type: 'student',
      },
      pseudonym: {
        unique_id: payload.username,
        password: payload.password,
        password_confirmation: payload.confirmPassword,
        ...(payload.email && {path: payload.email}),
      },
      self_enrollment: '1',
      pseudonym_type: 'username',
    },
  })

  return {status: response.status, data: json ?? {success: false}}
}
