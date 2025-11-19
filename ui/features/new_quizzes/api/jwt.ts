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

export interface NewQuizzesJwtResponse {
  token: string
}

/**
 * Fetches a JWT token for New Quizzes native launch
 * The token includes the 'new_quizzes_native_launch' workflow and course context
 */
export const fetchNewQuizzesToken = (accountId: string): Promise<NewQuizzesJwtResponse> =>
  fetch(
    `/api/v1/jwts?canvas_audience=false&workflows[]=new_quizzes_native_launch&context_id=${accountId}&context_type=account`,
    {
      method: 'POST',
      ...defaultFetchOptions(),
    },
  )
    .then(resp => {
      if (!resp.ok) {
        throw new Error(`Failed to fetch New Quizzes JWT: ${resp.status} ${resp.statusText}`)
      }
      return resp.json()
    })
    .then(data => ({token: data.token}))
