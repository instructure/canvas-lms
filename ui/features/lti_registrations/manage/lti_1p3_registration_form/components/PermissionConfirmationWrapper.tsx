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

import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {PermissionConfirmation} from '../../registration_wizard_forms/PermissionConfirmation'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {LtiScope, LtiScopes} from '@canvas/lti/model/LtiScope'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'

export type PermissionConfirmationWrapperProps = {
  internalConfig: InternalLtiConfiguration
  overlayStore: Lti1p3RegistrationOverlayStore
  scopesSupported?: Array<LtiScope>
  showAllSettings: boolean
  registrationUpdateRequest?: LtiRegistrationUpdateRequest
}

export const PermissionConfirmationWrapper = ({
  overlayStore,
  internalConfig,
  showAllSettings,
  scopesSupported,
  registrationUpdateRequest,
}: PermissionConfirmationWrapperProps) => {
  const {state, ...actions} = overlayStore()

  return (
    <RegistrationModalBody>
      <PermissionConfirmation
        showAllSettings={showAllSettings}
        mode="new"
        appName={internalConfig.title}
        scopesSelected={state.permissions.scopes ?? []}
        scopesSupported={scopesSupported ? scopesSupported : [...Object.values(LtiScopes)]}
        onScopeToggled={actions.toggleScope}
        registrationUpdateRequest={registrationUpdateRequest}
      />
    </RegistrationModalBody>
  )
}
