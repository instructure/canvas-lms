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

import type {DynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import type {ConfirmationStateType} from '../DynamicRegistrationWizardState'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {ReviewScreen} from '../../registration_wizard_forms/ReviewScreen'
import type {LtiPlacement} from '../../model/LtiPlacement'
import type {LtiRegistrationWithConfiguration} from '../../model/LtiRegistration'
export type ReviewScreenWrapperProps = {
  registration: LtiRegistrationWithConfiguration
  overlayStore: DynamicRegistrationOverlayStore
  transitionToConfirmationState: (from: ConfirmationStateType, to: ConfirmationStateType) => void
}

export const ReviewScreenWrapper = ({
  registration,
  overlayStore,
  transitionToConfirmationState,
}: ReviewScreenWrapperProps) => {
  const [overlayState] = useOverlayStore(overlayStore)
  const scopes = registration.configuration.scopes.filter(
    s => !overlayState.overlay.disabled_scopes?.includes(s),
  )
  // The API sometimes returns null for some fields, but the types are
  // optional, not nullable, so we have to do this weird thing to make TS happy.
  const privacyLevel =
    overlayState.overlay.privacy_level ?? registration.configuration.privacy_level ?? 'anonymous'
  const placements =
    registration.configuration.placements
      .filter(p => !overlayState.overlay.disabled_placements?.includes(p.placement))
      ?.map(p => p.placement) ?? []

  const toolName = overlayState.adminNickname ?? registration.name ?? ''
  const description = overlayState.overlay.description ?? undefined
  const labels = placements.reduce(
    (acc, p) => {
      acc[p] = overlayState.overlay.placements?.[p]?.text ?? undefined
      return acc
    },
    {} as Partial<Record<LtiPlacement, string>>,
  )

  const defaultIconUrl = registration.configuration?.launch_settings?.icon_url ?? undefined
  const defaultPlacementIconUrls = placements.reduce(
    (acc, p) => {
      acc[p] =
        registration.configuration?.placements?.find(placement => placement.placement === p)
          ?.icon_url ?? undefined
      return acc
    },
    {} as Partial<Record<LtiPlacement, string>>,
  )
  const iconUrls =
    placements?.reduce(
      (acc, p) => {
        acc[p] = overlayState.overlay.placements?.[p]?.icon_url ?? undefined
        return acc
      },
      {} as Partial<Record<LtiPlacement, string>>,
    ) ?? {}

  return (
    <ReviewScreen
      privacyLevel={privacyLevel}
      placements={placements}
      labels={labels}
      iconUrls={iconUrls}
      scopes={scopes}
      nickname={toolName}
      description={description}
      defaultPlacementIconUrls={defaultPlacementIconUrls}
      defaultIconUrl={defaultIconUrl}
      onEditScopes={() => transitionToConfirmationState('Reviewing', 'PermissionConfirmation')}
      onEditNaming={() => transitionToConfirmationState('Reviewing', 'NamingConfirmation')}
      onEditPlacements={() => transitionToConfirmationState('Reviewing', 'PlacementsConfirmation')}
      onEditPrivacyLevel={() =>
        transitionToConfirmationState('Reviewing', 'PrivacyLevelConfirmation')
      }
      onEditIconUrls={() => transitionToConfirmationState('Reviewing', 'IconConfirmation')}
    />
  )
}
