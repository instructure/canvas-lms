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
import type {RegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {usePlacements} from '../hooks/usePlacements'

export type NamingConfirmationWrapperProps = {
  overlayStore: RegistrationOverlayStore
  registration: LtiImsRegistration
}

export const NamingConfirmationWrapper = ({
  overlayStore,
  registration,
}: NamingConfirmationWrapperProps) => {
  const [state, actions] = useOverlayStore(overlayStore)
  const placements = usePlacements(registration)
    .filter(p => !state.registration.disabledPlacements?.includes(p))
    .map(p => ({
      placement: p,
      label: state.registration.placements?.find(pl => pl.type === p)?.label ?? '',
    }))

  return (
    <NamingConfirmation
      toolName={registration.client_name}
      adminNickname={state.adminNickname}
      onUpdateAdminNickname={actions.updateAdminNickname}
      description={
        state.registration.description ?? registration.default_configuration.description ?? ''
      }
      onUpdateDescription={actions.updateDescription}
      placements={placements}
      onUpdatePlacementLabel={(placement, value) => {
        actions.updatePlacement(placement)(overlay => ({
          ...overlay,
          label: value,
        }))
      }}
    />
  )
}
