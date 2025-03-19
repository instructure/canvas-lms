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
import type {DynamicRegistrationActions} from '../DynamicRegistrationWizardState'
import {IconConfirmation} from '../../registration_wizard_forms/IconConfirmation'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
import {
  type LtiPlacement,
  LtiPlacementsWithIcons,
  type LtiPlacementWithIcon,
} from '../../model/LtiPlacement'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'
import {Footer} from '../../registration_wizard_forms/Footer'
import {
  getInputIdForField,
  validateIconUris,
} from '../../registration_overlay/validateLti1p3RegistrationOverlayState'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import {Lti1p3RegistrationOverlayState} from '../../registration_overlay/Lti1p3RegistrationOverlayState'
export type IconConfirmationProps = {
  overlayStore: DynamicRegistrationOverlayStore
  registration: LtiRegistrationWithConfiguration
  reviewing: boolean
  transitionToConfirmationState: DynamicRegistrationActions['transitionToConfirmationState']
  transitionToReviewingState: DynamicRegistrationActions['transitionToReviewingState']
}

export const IconConfirmationWrapper = ({
  overlayStore,
  registration,
  reviewing,
  transitionToConfirmationState,
  transitionToReviewingState,
}: IconConfirmationProps) => {
  const [overlayState, actions] = useOverlayStore(overlayStore)
  const placements = registration.configuration.placements.map(p => p.placement)
  const iconPlacements = React.useMemo(
    () =>
      placements.filter((p): p is LtiPlacementWithIcon =>
        LtiPlacementsWithIcons.includes(p as LtiPlacementWithIcon),
      ),
    [placements],
  )
  const placementsWithUrls = iconPlacements.reduce((acc, placement) => {
    const iconUrl = overlayState.overlay.placements?.[placement]?.icon_url
    return {
      ...acc,
      [placement]: iconUrl ?? '',
    }
  }, {})
  const [hasSubmitted, setHasSubmitted] = React.useState(false)

  const onNextClicked = React.useCallback(() => {
    const {state} = overlayStore.getState()
    // if there are any errors, don't proceed
    const icon_urls = LtiPlacementsWithIcons.toSorted().reduce(
      (obj, p) => {
        const placement_overlay = state.overlay?.placements ? state.overlay.placements[p] : {}
        return {...obj, [p]: placement_overlay?.icon_url}
      },
      {} as Lti1p3RegistrationOverlayState['icons']['placements'],
    )

    const errors = validateIconUris({placements: icon_urls})

    if (errors.length > 0) {
      document.getElementById(getInputIdForField(errors[0].field))?.focus()
      setHasSubmitted(true)
    } else {
      transitionToReviewingState('IconConfirmation')
    }
  }, [transitionToReviewingState, overlayStore])

  const onPreviousButtonClicked = React.useCallback(() => {
    transitionToConfirmationState('IconConfirmation', 'NamingConfirmation')
  }, [transitionToConfirmationState])

  return (
    <>
      <RegistrationModalBody>
        <IconConfirmation
          allPlacements={placements}
          internalConfig={registration.configuration}
          name={overlayState.adminNickname ?? registration.name}
          placementIconOverrides={placementsWithUrls}
          setPlacementIconUrl={actions.updateIconUrl}
          developerKeyId={registration.developer_key_id ?? undefined}
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
