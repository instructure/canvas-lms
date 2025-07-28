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
import {NamingConfirmation} from '../../registration_wizard_forms/NamingConfirmation'
import type {DynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
import {useOverlayStore} from '../hooks/useOverlayStore'

export type NamingConfirmationWrapperProps = {
  overlayStore: DynamicRegistrationOverlayStore
  registration: LtiRegistrationWithConfiguration
}

export const NamingConfirmationWrapper = ({
  overlayStore,
  registration,
}: NamingConfirmationWrapperProps) => {
  const [state, actions] = useOverlayStore(overlayStore)
  const placements = registration.configuration.placements
    .filter(p => !state.overlay.disabled_placements?.includes(p.placement))
    .map(p => ({
      placement: p.placement,
      label: state.overlay.placements?.[p.placement]?.text ?? '',
    }))

  return (
    <NamingConfirmation
      toolName={registration.name}
      adminNickname={state.adminNickname}
      onUpdateAdminNickname={actions.updateAdminNickname}
      description={state.overlay.description ?? registration.configuration.description ?? ''}
      onUpdateDescription={actions.updateDescription}
      placements={placements}
      onUpdatePlacementLabel={(placement, value) => {
        actions.updatePlacement(placement)(overlay => ({
          ...overlay,
          text: value,
        }))
      }}
    />
  )
}
