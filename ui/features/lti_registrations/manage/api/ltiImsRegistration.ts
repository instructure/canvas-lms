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
import type {RegistrationOverlay} from '../model/RegistrationOverlay'
import {parseFetchResult} from '../../common/lib/apiResult/ApiResult'
import {ZDynamicRegistrationToken} from '../model/DynamicRegistrationToken'
import {ZLtiImsRegistration} from '../model/lti_ims_registration/LtiImsRegistration'
import {type AccountId} from '../model/AccountId'
import type {DynamicRegistrationTokenUUID} from '../model/DynamicRegistrationTokenUUID'
import type {LtiImsRegistrationId} from '../model/lti_ims_registration/LtiImsRegistrationId'
import {defaultFetchOptions} from '@canvas/util/xhr'

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
export const fetchRegistrationToken = (accountId: AccountId, unifiedToolId: string = '') =>
  parseFetchResult(ZDynamicRegistrationToken)(
    fetch(
      `/api/lti/accounts/${accountId}/registration_token?unified_tool_id=${unifiedToolId}`,
      defaultFetchOptions()
    )
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
export const getRegistrationByUUID = (
  accountId: AccountId,
  registrationUuid: DynamicRegistrationTokenUUID
) =>
  parseFetchResult(ZLtiImsRegistration)(
    fetch(
      `/api/lti/accounts/${accountId}/registrations/uuid/${registrationUuid}`,
      defaultFetchOptions()
    )
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
  overlay: RegistrationOverlay
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
    })
  )
