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
import {AllLtiScopes} from '@canvas/lti/model/LtiScope'
import * as React from 'react'
import {PermissionConfirmation} from '../../../../manage/registration_wizard_forms/PermissionConfirmation'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {Lti1p3RegistrationOverlayStore} from '../../../registration_overlay/Lti1p3RegistrationOverlayStore'

type PermissionConfirmationPerfWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  registration: LtiRegistrationWithAllInformation
  showAllSettings: boolean
}

/**
 * A wrapper around the PermissionConfirmation component that uses the
 * Lti1p3RegistrationOverlayStore to manage the state of the
 * permissions.
 *
 * This perf wrapper is used to avoid re-rendering the entire form.
 *
 * Once the DynamicRegistrationWizard is refactored to use the
 * Lti1p3RegistrationOverlayStore, these optimizations can be moved
 * into the PermissionConfirmation component itself, and this
 * wrapper can be removed.
 * @param param0
 * @returns
 */
export const PermissionConfirmationPerfWrapper = React.memo(
  ({overlayStore, registration, showAllSettings}: PermissionConfirmationPerfWrapperProps) => {
    const {scopesSelected, toggleScope} = overlayStore(s => ({
      scopesSelected: s.state.permissions.scopes || [],
      toggleScope: s.toggleScope,
    }))
    const possibleScopes = showAllSettings ? AllLtiScopes : registration.configuration.scopes

    return (
      <PermissionConfirmation
        mode="edit"
        showAllSettings={showAllSettings}
        appName={registration.name}
        scopesSelected={scopesSelected}
        scopesSupported={possibleScopes}
        onScopeToggled={toggleScope}
      />
    )
  },
)
