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
import {PlacementsConfirmation} from '../../registration_wizard_forms/PlacementsConfirmation'
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {AllLtiPlacements, InternalOnlyLtiPlacements} from '../../model/LtiPlacement'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'

export type PlacementsConfirmationProps = {
  internalConfig: InternalLtiConfiguration
  overlayStore: Lti1p3RegistrationOverlayStore
}

const allPlacements = [...AllLtiPlacements].sort()

export const PlacementsConfirmationWrapper = ({
  internalConfig,
  overlayStore,
}: PlacementsConfirmationProps) => {
  const {state, ...actions} = overlayStore()

  const internalConfigPlacements = internalConfig.placements.map(p => p.placement)
  const availablePlacements = allPlacements.filter(
    p => !InternalOnlyLtiPlacements.includes(p as any) || internalConfigPlacements.includes(p),
  )

  return (
    <RegistrationModalBody>
      <PlacementsConfirmation
        appName={internalConfig.title}
        availablePlacements={availablePlacements.filter(p => {
          if (!window.ENV.FEATURES.lti_asset_processor) {
            return p !== 'ActivityAssetProcessor'
          }
          return true
        })}
        enabledPlacements={state.placements.placements ?? []}
        courseNavigationDefaultHidden={state.placements.courseNavigationDefaultDisabled ?? false}
        onToggleDefaultDisabled={actions.toggleCourseNavigationDefaultDisabled}
        onTogglePlacement={actions.togglePlacement}
      />
    </RegistrationModalBody>
  )
}
