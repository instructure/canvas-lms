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

import {ZLtiRegistration, type LtiRegistration} from '../model/LtiRegistration'
import {success, apiParseError, type ApiResult} from '../../common/lib/apiResult/ApiResult'
import {ZPaginatedList, type PaginatedList} from './PaginatedList'
import {type LtiRegistrationId} from '../model/LtiRegistrationId'
import {mockFetchSampleLtiRegistrations, mockDeleteRegistration} from './sampleLtiRegistrations'

export type AppsSortProperty =
  | 'name'
  | 'nickname'
  | 'lti_version'
  | 'installed'
  | 'installed_by'
  | 'on'

export type AppsSortDirection = 'asc' | 'desc'

export type FetchRegistrations = (options: {
  query: string
  sort: AppsSortProperty
  dir: AppsSortDirection
  offset: number
  limit: number
}) => Promise<ApiResult<PaginatedList<LtiRegistration>>>

export const fetchRegistrations: FetchRegistrations = options => {
  // todo: implement this with the actual fetch call
  return mockFetchSampleLtiRegistrations(options)
    .then(ZPaginatedList(ZLtiRegistration).safeParse)
    .then(result => {
      return result.success
        ? success(result.data)
        : apiParseError(result.error.errors.map(e => e.message).join('\n\n'))
    })
}

export type DeleteRegistration = (id: LtiRegistrationId) => Promise<ApiResult<void>>

// todo: implement this with the actual delete call
export const deleteRegistration: DeleteRegistration = id =>
  mockDeleteRegistration(id).then(() => success(undefined))
