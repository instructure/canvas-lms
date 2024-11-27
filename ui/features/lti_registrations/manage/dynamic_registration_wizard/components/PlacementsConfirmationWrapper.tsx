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
import type {RegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {PlacementsConfirmation} from '../../registration_wizard_forms/PlacementsConfirmation'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {usePlacements} from '../hooks/usePlacements'

export type PlacementsConfirmationProps = {
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
}

export const PlacementsConfirmationWrapper = ({
  registration,
  overlayStore,
}: PlacementsConfirmationProps) => {
  const [overlayState, actions] = useOverlayStore(overlayStore)
  const placements = usePlacements(registration)

  return (
    <PlacementsConfirmation
      appName={registration.client_name}
      availablePlacements={placements}
      enabledPlacements={placements.filter(
        p => !overlayState.registration.disabledPlacements?.includes(p)
      )}
      courseNavigationDefaultHidden={
        // @ts-expect-error
        overlayState.registration.placements?.find(p => p.type === 'course_navigation')?.default ===
          'disabled' ?? false
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
