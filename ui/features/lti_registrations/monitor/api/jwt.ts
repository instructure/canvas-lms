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

import {AccountId} from '@canvas/lti-apps/models/AccountId'
import {defaultFetchOptions} from '@canvas/util/xhr'

export const fetchLtiUsageToken = (accountId: AccountId) =>
  fetch(
    `/api/v1/jwts?canvas_audience=false&workflows[]=lti_usage&context_id=${accountId}&context_type=account`,
    {
      method: 'POST',
      ...defaultFetchOptions(),
    },
  )
    .then(resp => resp.json())
    .then(data => ({token: data.token}))
