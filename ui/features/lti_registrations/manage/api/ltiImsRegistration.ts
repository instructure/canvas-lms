/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {parseFetchResult} from '../../common/lib/apiResult/ApiResult'
import {ZDynamicRegistrationToken} from '../model/DynamicRegistrationToken'
import type {AccountId} from '../model/AccountId'
import {useQuery} from '@tanstack/react-query'
import {doFetchWithSchema} from '@canvas/do-fetch-api-effect'
import type {DynamicRegistrationTokenUUID} from '../model/DynamicRegistrationTokenUUID'
import {defaultFetchOptions} from '@canvas/util/xhr'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {ZLtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {LtiRegistrationId} from '../model/LtiRegistrationId'
import {
  LtiRegistrationUpdateRequest,
  ZLtiRegistrationUpdateRequest,
} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {ZLtiImsRegistration} from '../model/lti_ims_registration/LtiImsRegistration'
import {LtiImsRegistrationId} from '../model/lti_ims_registration/LtiImsRegistrationId'
import {RegistrationOverlay} from '../model/RegistrationOverlay'
import {LtiRegistrationUpdateRequestId} from '../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {z} from 'zod'
import {LtiOverlay} from '../model/LtiOverlay'
import {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'

/**
 * Fetch a newly generated registration token which will
 * be used to send a registration request to the tool.
 * This token is also used to fetch the registration
 * after it's created by the tool.
 *
 * @param accountId
 * @param unifiedToolId included in token. optional.
 * @returns
 */
export const fetchRegistrationToken = (
  accountId: AccountId,
  registrationUrl: string,
  unifiedToolId?: UnifiedToolId,
  /**
   * The existing registration to update
   */
  registrationId?: LtiRegistrationId,
) =>
  parseFetchResult(ZDynamicRegistrationToken)(
    fetch(
      `/api/lti/accounts/${accountId}/registration_token?unified_tool_id=${
        unifiedToolId || ''
      }&registration_url=${registrationUrl.trim()}
      ${registrationId ? `&registration_id=${registrationId}` : ''}`,
      defaultFetchOptions(),
    ),
  )

/**
 * Retrieve a newly-created registration by its UUID.
 * Useful for the dynamic registration flow for after
 * the tool has created the registration & returned
 * the flow to the platform.
 *
 * @param accountId
 * @param registrationUuid uuid of the registration
 *   from the registration token
 * @returns
 */
export const getLtiRegistrationByUUID = (
  accountId: AccountId,
  registrationUuid: DynamicRegistrationTokenUUID,
) =>
  parseFetchResult(ZLtiRegistrationWithConfiguration)(
    fetch(
      `/api/lti/accounts/${accountId}/lti_registrations/uuid/${registrationUuid}`,
      defaultFetchOptions(),
    ),
  )

/**
 * Retrieve a newly created registration update request
 * by its UUID.
 *
 * This is used in the dynamic registration flow for after
 * the tool has gone through the registration update process
 * and returned the flow to the platform.
 *
 * @param accountId
 * @param registrationUuid uuid of the registration update request
 * @returns
 */
export const getLtiRegistrationUpdateRequestByUUID = (
  accountId: AccountId,
  registrationUuid: DynamicRegistrationTokenUUID,
) =>
  parseFetchResult(ZLtiRegistrationUpdateRequest)(
    fetch(
      `/api/lti/accounts/${accountId}/lti_registration_update_request/uuid/${registrationUuid}`,
      defaultFetchOptions(),
    ),
  )

/**
 * Retrieve a registration update request by its ID.
 *
 * @param accountId
 * @param registrationUpdateRequestId ID of the registration update request
 * @returns
 */
export const getLtiRegistrationUpdateRequestById = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  registrationUpdateRequestId: LtiRegistrationUpdateRequestId,
) =>
  parseFetchResult(ZLtiRegistrationUpdateRequest)(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/update_requests/${registrationUpdateRequestId}`,
      defaultFetchOptions(),
    ),
  )

/**
 * React Query hook to fetch a registration update request by its ID
 * @param accountId
 * @param registrationId
 * @param registrationUpdateRequestId
 * @returns React Query result
 */
export const useRegistrationUpdateRequest = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  registrationUpdateRequestId: LtiRegistrationUpdateRequestId,
) => {
  return useQuery({
    queryKey: [
      accountId,
      'lti_registration_update_request',
      registrationId,
      registrationUpdateRequestId,
    ],
    queryFn: () =>
      doFetchWithSchema(
        {
          path: `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/update_requests/${registrationUpdateRequestId}`,
        },
        ZLtiRegistrationUpdateRequest,
      ),
    staleTime: 1000 * 60 * 5, // 5 minutes
  })
}

/**
 * Retrieve a registration by its ID. Useful for managing a registration
 * after it's been created.
 *
 * @param accountId
 * @param registrationId ID of the registration
 * @returns
 */
export const getLtiImsRegistrationById = (
  accountId: AccountId,
  registrationId: LtiImsRegistrationId,
) =>
  parseFetchResult(ZLtiImsRegistration)(
    fetch(`/api/lti/accounts/${accountId}/registrations/${registrationId}`, defaultFetchOptions()),
  )

/**
 * Updates the overlay for an LtiImsRegistration.
 * @param accountId
 * @param registrationId
 * @param overlay
 * @returns
 */
export const updateRegistrationOverlay = (
  accountId: AccountId,
  registrationId: LtiImsRegistrationId,
  overlay: RegistrationOverlay,
) =>
  parseFetchResult(ZLtiImsRegistration)(
    fetch(`/api/lti/accounts/${accountId}/registrations/${registrationId}/overlay`, {
      ...defaultFetchOptions(),
      method: 'PUT',
      headers: {
        ...defaultFetchOptions().headers,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(overlay),
    }),
  )

export const applyLtiRegistrationUpdateRequest = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  registrationUpdateRequestId: LtiRegistrationUpdateRequestId,
  ltiOverlay: LtiConfigurationOverlay,
) =>
  parseFetchResult(z.unknown())(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/update_requests/${registrationUpdateRequestId}/apply`,
      {
        method: 'PUT',
        ...defaultFetchOptions({
          headers: {
            'Content-Type': 'application/json',
          },
        }),
        body: JSON.stringify({overlay: ltiOverlay, accepted: true}),
      },
    ),
  )
