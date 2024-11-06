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
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {
  canvasPlatformSettings,
  type RegistrationOverlayStore,
} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import {placementInState, type ConfirmationStateType} from '../DynamicRegistrationWizardState'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {ReviewScreen} from '../../registration_wizard_forms/ReviewScreen'
import type {LtiPlacement} from '../../model/LtiPlacement'

export type ReviewScreenWrapperProps = {
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
  transitionToConfirmationState: (from: ConfirmationStateType, to: ConfirmationStateType) => void
}

export const ReviewScreenWrapper = ({
  registration,
  overlayStore,
  transitionToConfirmationState,
}: ReviewScreenWrapperProps) => {
  const [overlayState] = useOverlayStore(overlayStore)
  const scopes = registration.scopes.filter(
    s => !overlayState.registration.disabledScopes?.includes(s)
  )

  // The API sometimes returns null for some fields, but the types are
  // optional, not nullable, so we have to do this weird thing to make TS happy.
  const privacyLevel =
    overlayState.registration.privacy_level ??
    canvasPlatformSettings(registration.tool_configuration)?.privacy_level ??
    undefined
  const placements =
    canvasPlatformSettings(registration.tool_configuration)
      ?.settings.placements.filter(
        p => !overlayState.registration.disabledPlacements?.includes(p.placement)
      )
      ?.map(p => p.placement) ?? []

  const toolName = overlayState.adminNickname ?? registration.client_name ?? ''
  const description = overlayState.registration.description ?? undefined
  const labels =
    overlayState.registration.placements?.reduce((acc, p) => {
      acc[p.type] = p.label !== null ? p.label : undefined
      return acc
    }, {} as Partial<Record<LtiPlacement, string>>) ?? {}

  const defaultIconUrl =
    canvasPlatformSettings(registration.tool_configuration)?.settings.icon_url ?? undefined
  const defaultPlacementIconUrls =
    canvasPlatformSettings(registration.tool_configuration)?.settings.placements.reduce(
      (acc, p) => {
        acc[p.placement] = p.icon_url !== null ? p.icon_url : undefined
        return acc
      },
      {} as Partial<Record<LtiPlacement, string>>
    ) ?? {}
  const iconUrls =
    placements?.reduce((acc, p) => {
      acc[p] = placementInState(overlayState, p)?.icon_url ?? undefined
      return acc
    }, {} as Partial<Record<LtiPlacement, string>>) ?? {}

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
