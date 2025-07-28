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
import {PlacementsConfirmation} from '../../registration_wizard_forms/PlacementsConfirmation'
import {useOverlayStore} from '../hooks/useOverlayStore'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
import {InternalOnlyLtiPlacements} from '../../model/LtiPlacement'

export type PlacementsConfirmationProps = {
  registration: LtiRegistrationWithConfiguration
  overlayStore: DynamicRegistrationOverlayStore
}

export const PlacementsConfirmationWrapper = ({
  registration,
  overlayStore,
}: PlacementsConfirmationProps) => {
  const [overlayState, actions] = useOverlayStore(overlayStore)
  const requestedPlacements = Object.keys(overlayState.overlay.placements ?? {})
  const placements = registration.configuration.placements
    .filter(
      p =>
        !InternalOnlyLtiPlacements.includes(p.placement as any) ||
        requestedPlacements.includes(p.placement),
    )
    .map(p => p.placement)

  return (
    <PlacementsConfirmation
      appName={registration.name}
      availablePlacements={placements}
      enabledPlacements={placements.filter(
        p => !overlayState.overlay.disabled_placements?.includes(p),
      )}
      courseNavigationDefaultHidden={
        overlayState.overlay.placements?.course_navigation?.default === 'disabled'
      }
      onToggleDefaultDisabled={() =>
        actions.updatePlacement('course_navigation')(prevState => {
          return {
            ...prevState,
            default: prevState.default === 'enabled' ? 'disabled' : 'enabled',
          }
        })
      }
      onTogglePlacement={placement => actions.toggleDisabledPlacement(placement)}
    />
  )
}
