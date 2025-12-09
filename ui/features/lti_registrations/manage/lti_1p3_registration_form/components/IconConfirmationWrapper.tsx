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
import {Footer} from '../../registration_wizard_forms/Footer'
import {
  getInputIdForField,
  validateIconUris,
} from '../../registration_overlay/validateLti1p3RegistrationOverlayState'
import {filterPlacementsByFeatureFlags} from '@canvas/lti/model/LtiPlacementFilter'

export type IconConfirmationWrapperProps = {
  onNextButtonClicked: () => void
  onPreviousButtonClicked: () => void
  reviewing: boolean
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
}

export const IconConfirmationWrapper = ({
  overlayStore,
  internalConfig,
  reviewing,
  onNextButtonClicked,
  onPreviousButtonClicked,
}: IconConfirmationWrapperProps) => {
  const {state, ...actions} = overlayStore()

  const [hasSubmitted, setHasSubmitted] = React.useState(false)

  const onNextClicked = React.useCallback(() => {
    // if there are any errors, don't proceed
    const errors = validateIconUris(overlayStore.getState().state.icons)
    if (errors.length > 0) {
      document.getElementById(getInputIdForField(errors[0].field))?.focus()
    } else {
      onNextButtonClicked()
    }
    setHasSubmitted(true)
  }, [onNextButtonClicked, overlayStore])

  const filteredPlacements = React.useMemo(
    () => filterPlacementsByFeatureFlags(state.placements.placements ?? []),
    [state.placements.placements],
  )

  return (
    <>
      <RegistrationModalBody>
        <IconConfirmation
          internalConfig={internalConfig}
          name={internalConfig.title}
          allPlacements={filteredPlacements}
          placementIconOverrides={state.icons.placements}
          setPlacementIconUrl={actions.setPlacementIconUrl}
          defaultIconUrl={state.icons.defaultIconUrl ?? ''}
          setDefaultIconUrl={actions.setDefaultIconUrl}
          hasSubmitted={hasSubmitted}
        />
      </RegistrationModalBody>
      <Footer
        reviewing={reviewing}
        currentScreen="intermediate"
        onPreviousClicked={onPreviousButtonClicked}
        onNextClicked={onNextClicked}
      />
    </>
  )
}
