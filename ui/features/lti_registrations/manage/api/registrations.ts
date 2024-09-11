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
import {
  type ApiResult,
  parseFetchResult,
  success,
  apiError,
  mapApiResult,
} from '../../common/lib/apiResult/ApiResult'
import {ZPaginatedList, type PaginatedList} from './PaginatedList'
import {type LtiRegistrationId} from '../model/LtiRegistrationId'
import type {AccountId} from '../model/AccountId'
import {defaultFetchOptions} from '@canvas/util/xhr'
import * as z from 'zod'
import {
  ZInternalLtiConfiguration,
  type InternalLtiConfiguration,
} from '../model/internal_lti_configuration/InternalLtiConfiguration'

export type AppsSortProperty =
  | 'name'
  | 'nickname'
  | 'lti_version'
  | 'installed'
  | 'installed_by'
  | 'updated_by'
  | 'on'

export type AppsSortDirection = 'asc' | 'desc'

export type FetchRegistrations = (options: {
  accountId: AccountId
  query: string
  sort: AppsSortProperty
  dir: AppsSortDirection
  page: number
  limit: number
}) => Promise<ApiResult<PaginatedList<LtiRegistration>>>

export const fetchRegistrations: FetchRegistrations = options =>
  parseFetchResult(ZPaginatedList(ZLtiRegistration))(
    fetch(
      `/api/v1/accounts/${options.accountId}/lti_registrations?` +
        new URLSearchParams({
          query: options.query,
          sort: options.sort,
          dir: options.dir,
          page: options.page.toString(),
          per_page: options.limit.toString(),
        }),
      defaultFetchOptions()
    )
  )

export type FetchThirdPartyToolConfiguration = (
  config:
    | {
        url: string
      }
    | {
        lti_configuration: unknown
      },
  accountId: AccountId
) => Promise<ApiResult<InternalLtiConfiguration>>

// POST
// validate: ({url: string} | {lti_configuration: LtiConfiguration}) ->
//   200 { configuration: InternalLtiConfiguration }
//   422 { errors: string[] }

export const fetchThirdPartyToolConfiguration: FetchThirdPartyToolConfiguration = (
  config,
  accountId
) =>
  parseFetchResult(
    z.object({
      configuration: ZInternalLtiConfiguration,
    })
  )(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/configuration/validate`, {
      method: 'POST',
      ...defaultFetchOptions({
        headers: {
          'Content-Type': 'application/json',
        },
      }),
      body: JSON.stringify(config),
    })
  ).then(result => mapApiResult(result, r => r.configuration))

export type DeleteRegistration = (
  accountId: AccountId,
  id: LtiRegistrationId
) => Promise<ApiResult<unknown>>

/**
 * Deletes an LTI registration
 * @param accountId
 * @param registrationId
 * @returns
 */
export const deleteRegistration: DeleteRegistration = (accountId, registrationId) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`, {
      ...defaultFetchOptions(),
      method: 'DELETE',
    })
  )
