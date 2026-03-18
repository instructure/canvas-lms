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

import type {
  bindGlobalLtiRegistration,
  fetchRegistrationByClientId,
  updateRegistration,
} from '../api/registrations'
import type {AccountId} from '../model/AccountId'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import type {LtiRegistrationWithAllInformation} from '../model/LtiRegistration'
import type {UnsuccessfulApiResult} from '../../common/lib/apiResult/ApiResult'
import type {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {convertToLtiConfigurationOverlay} from '../registration_overlay/Lti1p3RegistrationOverlayStateHelpers'

export interface InheritedKeyService {
  fetchRegistrationByClientId: typeof fetchRegistrationByClientId
  bindGlobalLtiRegistration: typeof bindGlobalLtiRegistration
  updateRegistration: typeof updateRegistration
  installInheritedRegistration: typeof installInheritedRegistration
}

export type InstallRegistrationParams = {
  accountId: AccountId
  registration: LtiRegistrationWithAllInformation
  overlayStore?: Lti1p3RegistrationOverlayStore
  service: InheritedKeyService
}

export type InstallRegistrationResult =
  | {
      _type: 'Success'
      registrationId: LtiRegistrationId
      registrationName: string
    }
  | UnsuccessfulApiResult

export const installInheritedRegistration = async ({
  accountId,
  registration,
  overlayStore,
  service,
}: InstallRegistrationParams): Promise<InstallRegistrationResult> => {
  try {
    const isTemplateFlagEnabled = window.ENV?.FEATURES?.lti_registrations_templates
    // with flag off, this creates account bindings
    // with flag on, this creates a local copy of the template registration
    const bindResult = await service.bindGlobalLtiRegistration(accountId, registration.id)

    if (bindResult._type !== 'Success') {
      return bindResult
    }

    let registrationId = registration.id
    let registrationName = registration.admin_nickname || registration.name

    if (isTemplateFlagEnabled && overlayStore) {
      const {overlay} = convertToLtiConfigurationOverlay(
        overlayStore.getState().state,
        registration.overlaid_configuration,
      )

      const localCopyId = bindResult.data.registration_id
      const adminNickname = overlayStore.getState().state.naming.nickname || registration.name

      const updateResult = await service.updateRegistration({
        accountId,
        registrationId: localCopyId,
        overlay,
        adminNickname,
      })

      if (updateResult._type !== 'Success') {
        return updateResult
      }

      registrationId = localCopyId
      registrationName = adminNickname
    }

    return {
      _type: 'Success',
      registrationId,
      registrationName,
    }
  } catch (error) {
    console.error('Failed to install app', error)
    return {
      _type: 'GenericError',
      message: error instanceof Error ? error.message : 'Unknown error',
    } as UnsuccessfulApiResult
  }
}
