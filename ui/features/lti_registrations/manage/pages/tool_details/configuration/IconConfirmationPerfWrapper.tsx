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
import * as React from 'react'
import {IconConfirmation} from '../../../registration_wizard_forms/IconConfirmation'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {Lti1p3RegistrationOverlayStore} from '../../../registration_overlay/Lti1p3RegistrationOverlayStore'

type IconConfirmationPerfWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  registration: LtiRegistrationWithAllInformation
}

/**
 * A wrapper around the IconConfirmation component that uses the
 * Lti1p3RegistrationOverlayStore to manage the state of the
 * permissions.
 *
 * This perf wrapper is used to avoid re-rendering the entire form.
 *
 * Once the DynamicRegistrationWizard is refactored to use the
 * Lti1p3RegistrationOverlayStore, these optimizations can be moved
 * into the IconConfirmation component itself, and this
 * wrapper can be removed.
 * @param param0
 * @returns
 */
export const IconConfirmationPerfWrapper = React.memo(
  ({overlayStore, registration}: IconConfirmationPerfWrapperProps) => {
    const {allPlacements, placementIconOverrides, setPlacementIconUrl, hasSubmitted} = overlayStore(
      s => ({
        allPlacements: s.state.placements.placements ?? [],
        placementIconOverrides: s.state.icons.placements,
        setPlacementIconUrl: s.setPlacementIconUrl,
        hasSubmitted: s.state.hasSubmitted,
      }),
    )

    return (
      <IconConfirmation
        internalConfig={registration.configuration}
        name={registration.name}
        allPlacements={allPlacements}
        placementIconOverrides={placementIconOverrides}
        setPlacementIconUrl={setPlacementIconUrl}
        hasSubmitted={hasSubmitted}
      />
    )
  },
)
