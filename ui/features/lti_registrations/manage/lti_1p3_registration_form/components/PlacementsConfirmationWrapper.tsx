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

import {PlacementsConfirmation} from '../../registration_wizard_forms/PlacementsConfirmation'
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {AllLtiPlacements, InternalOnlyLtiPlacements, LtiPlacement} from '../../model/LtiPlacement'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'

export type PlacementsConfirmationProps = {
  internalConfig: InternalLtiConfiguration
  overlayStore: Lti1p3RegistrationOverlayStore
  supportedPlacements?: Array<LtiPlacement>
  registrationUpdateRequest?: LtiRegistrationUpdateRequest
  existingRegistration?: LtiRegistrationWithConfiguration
}

const allPlacements = [...AllLtiPlacements].sort()

export const PlacementsConfirmationWrapper = ({
  internalConfig,
  overlayStore,
  supportedPlacements,
  registrationUpdateRequest,
  existingRegistration,
}: PlacementsConfirmationProps) => {
  const {state, ...actions} = overlayStore()

  const internalConfigPlacements = internalConfig.placements.map(p => p.placement)
  const availablePlacements = (supportedPlacements || allPlacements).filter(
    p => !InternalOnlyLtiPlacements.includes(p as any) || internalConfigPlacements.includes(p),
  )

  return (
    <RegistrationModalBody>
      <PlacementsConfirmation
        appName={internalConfig.title}
        availablePlacements={filterPlacementsByFeatureFlags(availablePlacements)}
        enabledPlacements={state.placements.placements ?? []}
        courseNavigationDefaultHidden={state.placements.courseNavigationDefaultDisabled ?? false}
        onToggleDefaultDisabled={actions.toggleCourseNavigationDefaultDisabled}
        topNavigationAllowFullscreen={state.placements.topNavigationAllowFullscreen ?? false}
        onToggleAllowFullscreen={actions.toggleTopNavigationAllowFullscreen}
        onTogglePlacement={actions.togglePlacement}
        registrationUpdateRequest={registrationUpdateRequest}
        existingRegistration={existingRegistration}
      />
    </RegistrationModalBody>
  )
}
