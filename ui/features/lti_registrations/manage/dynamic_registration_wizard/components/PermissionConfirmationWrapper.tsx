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

import React from 'react'
import type {DynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {PermissionConfirmation} from '../../registration_wizard_forms/PermissionConfirmation'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'

export type PermissionConfirmationWrapperProps = {
  registration: LtiRegistrationWithConfiguration
  overlayStore: DynamicRegistrationOverlayStore
}

export const PermissionConfirmationWrapper = ({
  registration,
  overlayStore,
}: PermissionConfirmationWrapperProps) => {
  const [state, actions] = useOverlayStore(overlayStore)
  return (
    <PermissionConfirmation
      showAllSettings={false}
      mode="new"
      appName={registration.name}
      scopesSelected={registration.configuration.scopes.filter(
        s => !state.overlay.disabled_scopes?.includes(s),
      )}
      scopesSupported={registration.configuration.scopes}
      onScopeToggled={actions.toggleDisabledScope}
    />
  )
}
