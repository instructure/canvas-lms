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
  ZLtiRegistrationWithLegacyConfiguration,
  type LtiRegistrationWithConfiguration,
  type LtiRegistrationWithLegacyConfiguration,
  ZLtiRegistrationWithAllInformation,
} from '../model/LtiRegistration'
import {
  type ApiResult,
  parseFetchResult,
  mapApiResult,
  exception,
} from '../../common/lib/apiResult/ApiResult'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import type {AccountId} from '../model/AccountId'
import {defaultFetchOptions} from '@canvas/util/xhr'
import * as z from 'zod'
import {
  ZInternalLtiConfiguration,
  type InternalLtiConfiguration,
} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'
import {compact} from '../../common/lib/compact'
import {type LtiOverlayVersion, ZLtiOverlayVersion} from '../model/LtiOverlayVersion'
import {
  type LtiRegistrationHistoryEntry,
  ZLtiRegistrationHistoryEntry,
} from '../model/LtiRegistrationHistoryEntry'
import {useMutation, useQuery} from '@tanstack/react-query'
import {doFetchWithSchema} from '@canvas/do-fetch-api-effect'
import {getAccountId} from '../../common/lib/getAccountId'
import {ZPaginatedList} from './PaginatedList'
import {queryClient} from '@canvas/query'
import {
  diffHistoryEntries,
  diffHistoryEntry,
  LtiHistoryEntryWithDiff,
} from '../pages/tool_details/history/differ'

export type AppsSortProperty =
  | 'name'
  | 'nickname'
  | 'lti_version'
  | 'installed'
  | 'updated'
  | 'installed_by'
  | 'updated_by'
  | 'on'
  | 'status'

export type AppsSortDirection = 'asc' | 'desc'

export const LIST_REGISTRATIONS_PAGE_LIMIT = 15

export const constructListRegistrationsQueryKey = ({
  accountId,
  query,
  sort,
  dir,
  page,
}: UseAppsOptions) => [accountId, 'lti_registrations', {query, sort, dir, page}]

export type UseAppsOptions = {
  accountId: AccountId
  query: string
  sort: AppsSortProperty
  dir: AppsSortDirection
  page: number
}

/**
 * useApps is a custom hook that fetches a list of LTI registrations for a given account, using the provided
 * options to filter, sort, and paginate the results.
 * @param The options to use when querying the back end for registrations
 * @returns A standard TanStack Query object representing the list of registrations.
 */
export const useApps = ({accountId, query, sort, dir, page}: UseAppsOptions) => {
  return useQuery({
    placeholderData: prev => prev,
    queryKey: constructListRegistrationsQueryKey({accountId, query, sort, dir, page}),
    queryFn: () =>
      doFetchWithSchema(
        {
          path:
            `/api/v1/accounts/${accountId}/lti_registrations?` +
            new URLSearchParams({
              query,
              sort,
              dir,
              page: page.toString(),
              per_page: LIST_REGISTRATIONS_PAGE_LIMIT.toString(),
            }),
        },
        ZPaginatedList(ZLtiRegistration),
      ),
    staleTime: 1000 * 60 * 5, // 5 minutes
  })
}

export const refreshRegistrations = (accountId?: AccountId) => {
  if (!accountId) {
    accountId = getAccountId()
  }
  queryClient.invalidateQueries({queryKey: [accountId, 'lti_registrations'], exact: false})
}

const createRegistrationWithAllInfoQueryKey = (
  ltiRegistrationId: LtiRegistrationId,
  accountId: AccountId,
) => [accountId, 'lti_registrations', ltiRegistrationId, 'allInfo']

export const useRegistrationWithAllInfo = (
  ltiRegistrationId: LtiRegistrationId,
  accountId: AccountId,
) => {
  return useQuery({
    queryKey: createRegistrationWithAllInfoQueryKey(ltiRegistrationId, accountId),
    queryFn: () => {
      return doFetchWithSchema(
        {
          path: `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}?include[]=overlaid_configuration&include[]=overlay&include[]=overlay_versions`,
        },
        ZLtiRegistrationWithAllInformation,
      )
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
  })
}

export const refreshRegistrationWithAllInfo = (
  ltiRegistrationId: LtiRegistrationId,
  accountId: AccountId,
) => {
  queryClient.invalidateQueries({
    queryKey: createRegistrationWithAllInfoQueryKey(ltiRegistrationId, accountId),
  })
}

const createRegistrationWithConfigQueryKey = (
  ltiRegistrationId: LtiRegistrationId,
  accountId: AccountId,
) => [accountId, 'lti_registrations', ltiRegistrationId, 'withConfig']

export const useRegistrationWithConfig = (
  ltiRegistrationId: LtiRegistrationId,
  accountId: AccountId,
) => {
  return useQuery({
    queryKey: createRegistrationWithConfigQueryKey(ltiRegistrationId, accountId),
    queryFn: () => {
      return doFetchWithSchema(
        {
          path: `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}?include[]=configuration&include[]=overlay`,
        },
        ZLtiRegistrationWithConfiguration,
      )
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
  })
}

export type FetchLtiRegistrationWithLegacyConfiguration = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
) => Promise<ApiResult<LtiRegistrationWithLegacyConfiguration>>

/**
 * Fetch a single LtiRegistration with its legacy configuration included
 * @returns
 */
export const fetchLtiRegistrationWithLegacyConfig: FetchLtiRegistrationWithLegacyConfiguration = (
  accountId,
  ltiRegistrationId,
) =>
  parseFetchResult(ZLtiRegistrationWithLegacyConfiguration)(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}?include=overlaid_legacy_configuration`,
      defaultFetchOptions(),
    ),
  )

export type ResetLtiRegistrationOptions = {
  ltiRegistrationId: LtiRegistrationId
  accountId: AccountId
}

export const useResetLtiRegistration = () => {
  return useMutation({
    mutationFn: ({ltiRegistrationId, accountId}: ResetLtiRegistrationOptions) =>
      doFetchWithSchema(
        {
          path: `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}/reset`,
          method: 'PUT',
        },
        ZLtiRegistrationWithConfiguration,
      ),
    onSettled: (_, __, {ltiRegistrationId, accountId}) => {
      refreshRegistrationWithAllInfo(ltiRegistrationId, accountId)
    },
  })
}

export type FetchThirdPartyToolConfiguration = (
  config:
    | {
        url: string
      }
    | {
        lti_configuration: unknown
      },
  accountId: AccountId,
) => Promise<ApiResult<InternalLtiConfiguration>>

// POST
// validate: ({url: string} | {lti_configuration: LtiConfiguration}) ->
//   200 { configuration: InternalLtiConfiguration }
//   422 { errors: string[] }

export const fetchThirdPartyToolConfiguration: FetchThirdPartyToolConfiguration = (
  config,
  accountId,
) =>
  parseFetchResult(
    z.object({
      configuration: ZInternalLtiConfiguration,
    }),
  )(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/configuration/validate`, {
      method: 'POST',
      ...defaultFetchOptions({
        headers: {
          'Content-Type': 'application/json',
        },
      }),
      body: JSON.stringify(config),
    }),
  ).then(result => mapApiResult(result, r => r.configuration))

export type DeleteRegistration = (
  accountId: AccountId,
  id: LtiRegistrationId,
) => Promise<ApiResult<unknown>>

/**
 * Deletes an LTI registration
 * @deprecated Please use the `useDeleteRegistration` hook instead.
 * @todo Remove this function once lti_registrations_next has been rolled out.
 * @param accountId
 * @param registrationId
 * @returns
 */
export const deleteRegistration: DeleteRegistration = (accountId, registrationId) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`, {
      ...defaultFetchOptions(),
      method: 'DELETE',
    }),
  )

export const useDeleteRegistration = () => {
  return useMutation({
    mutationFn: ({
      registrationId,
      accountId,
    }: {
      registrationId: LtiRegistrationId
      accountId: AccountId
    }) =>
      doFetchWithSchema(
        {
          method: 'DELETE',
          path: `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`,
        },
        z.unknown(),
      ),
    onSettled: (_, __, {accountId}) => {
      refreshRegistrations(accountId)
    },
  })
}

export type CreateRegistration = (
  accountId: AccountId,
  internalConfig: InternalLtiConfiguration,
  overlay?: LtiConfigurationOverlay,
  unifiedToolId?: string,
  adminNickname?: string,
) => Promise<ApiResult<LtiRegistrationWithConfiguration>>

/**
 * Creates an LTI registration
 * @param accountId The account id to create the registration in
 * @param internalConfig The internal configuration to use
 * @param overlay An overlay to apply to the internal configuration
 * @param unifiedToolId The unified tool id for the registration
 * @returns An ApiResult with the created registration including its ID
 */
export const createRegistration: CreateRegistration = (
  accountId,
  internalConfig,
  overlay,
  unifiedToolId,
  adminNickname,
) =>
  parseFetchResult(ZLtiRegistrationWithConfiguration)(
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
    }),
  )

type UpdateRegistrationParams = {
  accountId: AccountId
  registrationId: LtiRegistrationId
  internalConfig?: InternalLtiConfiguration
  overlay?: LtiConfigurationOverlay
  adminNickname?: string
  workflowState?: 'on' | 'off' | 'allow'
}

export type UpdateRegistration = (params: UpdateRegistrationParams) => Promise<ApiResult<unknown>>

export const useUpdateRegistration = () => {
  return useMutation({
    mutationFn: ({
      accountId,
      registrationId,
      internalConfig,
      overlay,
      adminNickname,
      workflowState,
    }: UpdateRegistrationParams) =>
      doFetchWithSchema(
        {
          method: 'PUT',
          path: `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`,
          body: compact({
            configuration: internalConfig,
            overlay,
            admin_nickname: adminNickname,
            workflow_state: workflowState,
          }),
        },
        z.unknown(),
      ),
    onSettled(_, __, {registrationId, accountId}) {
      refreshRegistrationWithAllInfo(registrationId, accountId)
    },
  })
}

/**
 * Updates an LTI registration
 * @param accountId The account id to update the registration in
 * @param registrationId The id of the registration to update
 * @param internalConfig The internal configuration to use
 * @param overlay An overlay to apply to the internal configuration
 * @param workflowState The workflow state the registration account binding should be set to
 * @returns An ApiResult with an unknown value. The value should be ignored.
 */
export const updateRegistration: UpdateRegistration = ({
  accountId,
  registrationId,
  internalConfig,
  overlay,
  adminNickname,
  workflowState,
}) =>
  parseFetchResult(z.unknown())(
    fetch(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}`, {
      ...defaultFetchOptions({
        headers: {
          'Content-Type': 'application/json',
        },
      }),
      method: 'PUT',
      body: JSON.stringify(
        compact({
          configuration: internalConfig,
          overlay,
          admin_nickname: adminNickname,
          workflow_state: workflowState,
        }),
      ),
    }),
  )

export const fetchRegistrationByClientId = (accountId: AccountId, clientId: DeveloperKeyId) =>
  parseFetchResult(ZLtiRegistrationWithConfiguration)(
    fetch(`/api/v1/accounts/${accountId}/lti_registration_by_client_id/${clientId}`, {
      ...defaultFetchOptions(),
    }),
  )

export const setGlobalLtiRegistrationWorkflowState = (
  accountId: AccountId,
  ltiRegistrationId: LtiRegistrationId,
  workflowState: 'on' | 'off',
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
        workflow_state: workflowState,
      }),
    }),
  )

export const bindGlobalLtiRegistration = (
  accountId: AccountId,
  ltiRegistrationId: LtiRegistrationId,
) => setGlobalLtiRegistrationWorkflowState(accountId, ltiRegistrationId, 'on')

export const unbindGlobalLtiRegistration = (
  accountId: AccountId,
  ltiRegistrationId: LtiRegistrationId,
) => setGlobalLtiRegistrationWorkflowState(accountId, ltiRegistrationId, 'off')

export type FetchLtiRegistration = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  includes?: Array<'overlay' | 'overlay_history'>,
) => Promise<ApiResult<LtiRegistrationWithConfiguration>>

/**
 * Fetch a single LtiRegistration
 * @returns
 */
export const fetchLtiRegistration: FetchLtiRegistration = (
  accountId,
  ltiRegistrationId,
  includes = ['overlay', 'overlay_history'],
) =>
  parseFetchResult(ZLtiRegistrationWithConfiguration)(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}?${includes
        .map(i => `include[]=${i}`)
        .join('&')}`,
      {
        ...defaultFetchOptions(),
      },
    ),
  )

export const fetchLtiRegistrationOverlayHistory = (
  accountId: AccountId,
  ltiRegistrationId: LtiRegistrationId,
  limit: number,
): Promise<ApiResult<LtiOverlayVersion[]>> =>
  parseFetchResult(z.array(ZLtiOverlayVersion))(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${ltiRegistrationId}/overlay_history?limit=${limit}`,
      defaultFetchOptions(),
    ),
  )

export type FetchLtiRegistrationHistoryArgs =
  | {
      accountId: AccountId
      ltiRegistrationId: LtiRegistrationId
    }
  | {
      url: string
    }

export const fetchLtiRegistrationHistory = async (
  args: FetchLtiRegistrationHistoryArgs,
): Promise<ApiResult<LtiHistoryEntryWithDiff[]>> => {
  let url: string
  if ('url' in args) {
    url = args.url
  } else {
    url = `/api/v1/accounts/${args.accountId}/lti_registrations/${args.ltiRegistrationId}/history`
  }
  return parseFetchResult(z.array(ZLtiRegistrationHistoryEntry))(fetch(url, defaultFetchOptions()))
    .then(r => mapApiResult(r, diffHistoryEntries))
    .catch(e => {
      console.error('Error fetching LTI registration history:', e)
      if (e instanceof Error) {
        return exception(e)
      } else {
        return exception(new Error('Encountered an unknown error diffing history entries'))
      }
    })
}
