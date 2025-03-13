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

import doFetchApi from '@canvas/do-fetch-api-effect'

export interface User {
  id: string
  name: string
  email?: string
  short_name?: string
  sis_user_id?: string
  login_id?: string
  integration_id?: string
  communication_channels: Array<string>
  pseudonyms: Array<string>
  enrollments: Array<string>
}

export interface CommunicationChannel {
  address: string
  type: string
}

export interface Login {
  unique_id: string
  account_id: string
}

export interface Enrollment {
  role: string
  course_id: string
  enrollment_state: string
}

export interface AccountSelectOption {
  id: string
  name: string
}

export const createUserToMergeQueryKey = (userId: string) => ['users', userId]

export const fetchUserWithRelations = async (userId: string) => {
  const {json} = await doFetchApi<User>({
    path: `/users/${userId}/user_for_merge`,
    method: 'GET',
  })

  return json!
}
