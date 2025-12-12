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
import {IconConfirmation} from '../../registration_wizard_forms/IconConfirmation'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'

export type IconConfirmationWrapperProps = {
  reviewing: boolean
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  includeFooter?: boolean
  hasClickedNext?: boolean
}

export const IconConfirmationWrapper = ({
  overlayStore,
  internalConfig,
  hasClickedNext,
}: IconConfirmationWrapperProps) => {
  const {state, ...actions} = overlayStore()

  const filteredPlacements = React.useMemo(
    () => filterPlacementsByFeatureFlags(state.placements.placements ?? []),
    [state.placements.placements],
  )

  return (
    <RegistrationModalBody>
      <IconConfirmation
        internalConfig={internalConfig}
        name={internalConfig.title}
        allPlacements={filteredPlacements}
        placementIconOverrides={state.icons.placements}
        setPlacementIconUrl={actions.setPlacementIconUrl}
        defaultIconUrl={state.icons.defaultIconUrl}
        setDefaultIconUrl={actions.setDefaultIconUrl}
        hasSubmitted={hasClickedNext ?? false}
      />
    </RegistrationModalBody>
  )
}
