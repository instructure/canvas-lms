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

import {
  ZLtiRegistrationWithConfiguration,
  ZLtiRegistration,
  type LtiRegistrationWithConfiguration,
  type LtiRegistration,
} from '../model/LtiRegistration'
import {
  type ApiResult,
  parseFetchResult,
  success,
  apiError,
  mapApiResult,
} from '../../common/lib/apiResult/ApiResult'
import {ZPaginatedList, type PaginatedList} from './PaginatedList'
import {type LtiRegistrationId} from '../model/LtiRegistrationId'
import {ZAccountId, type AccountId} from '../model/AccountId'
import {defaultFetchOptions} from '@canvas/util/xhr'
import * as z from 'zod'
import {
  ZInternalLtiConfiguration,
  type InternalLtiConfiguration,
} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import type DeveloperKey from 'features/developer_keys_v2/react/DeveloperKey'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'

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

export type CreateRegistration = (
  accountId: AccountId,
  internalConfig: InternalLtiConfiguration,
  overlay?: LtiConfigurationOverlay,
  unifiedToolId?: string,
  adminNickname?: string
) => Promise<ApiResult<unknown>>

/**
 * Creates an LTI registration
 * @param accountId The account id to create the registration in
 * @param internalConfig The internal configuration to use
 * @param overlay An overlay to apply to the internal configuration
 * @param unifiedToolId The unified tool id for the registration
 * @returns An ApiResult with an unknown value. The value should be ignored.
 */
export const createRegistration: CreateRegistration = (
  accountId,
  internalConfig,
  overlay,
  unifiedToolId,
  adminNickname
) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations`, {
      ...defaultFetchOptions({
        headers: {
          'Content-Type': 'application/json',
        },
      }),
      method: 'POST',
      body: JSON.stringify({
        admin_nickname: adminNickname,
        configuration: internalConfig,
        overlay,
        unified_tool_id: unifiedToolId,
        workflow_state: 'on',
      }),
    })
  )

export type UpdateRegistration = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  internalConfig: InternalLtiConfiguration,
  overlay?: LtiConfigurationOverlay,
  adminNickname?: string
) => Promise<ApiResult<unknown>>

/**
 * Updates an LTI registration
 * @param accountId The account id to update the registration in
 * @param registrationId The id of the registration to update
 * @param internalConfig The internal configuration to use
 * @param overlay An overlay to apply to the internal configuration
 * @param unifiedToolId The unified tool id for the registration
 * @returns An ApiResult with an unknown value. The value should be ignored.
 */
export const updateRegistration: UpdateRegistration = (
  accountId,
  registrationId,
  internalConfig,
  overlay,
  adminNickname
) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`, {
      ...defaultFetchOptions({
        headers: {
          'Content-Type': 'application/json',
        },
      }),
      method: 'PUT',
      body: JSON.stringify({
        configuration: internalConfig,
        overlay,
        admin_nickname: adminNickname,
      }),
    })
  )

export const fetchRegistrationByClientId = (accountId: AccountId, clientId: DeveloperKeyId) =>
  parseFetchResult(ZLtiRegistrationWithConfiguration)(
    fetch(`/api/v1/accounts/${accountId}/lti_registration_by_client_id/${clientId}`, {
      ...defaultFetchOptions(),
    })
  )

export const bindGlobalLtiRegistration = (
  accountId: AccountId,
  ltiRegistrationId: LtiRegistrationId
) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}/bind`, {
      ...defaultFetchOptions(),
      method: 'POST',
      headers: {
        ...defaultFetchOptions().headers,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        workflow_state: 'on',
      }),
    })
  )

export type FetchLtiRegistration = (
  accountId: AccountId,
  registrationId: LtiRegistrationId
) => Promise<ApiResult<LtiRegistrationWithConfiguration>>

/**
 * Fetch a single LtiRegistration
 * @returns
 */
export const fetchLtiRegistration: FetchLtiRegistration = (
  accountId,
  ltiRegistrationId,
  includes: Array<'overlay' | 'overlay_history'> = ['overlay', 'overlay_history']
) =>
  parseFetchResult(ZLtiRegistrationWithConfiguration)(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}?${includes
        .map(i => `include[]=${i}`)
        .join('&')}`,
      {
        ...defaultFetchOptions(),
      }
    )
  )
