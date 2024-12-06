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
import {ReviewScreen} from '../../registration_wizard_forms/ReviewScreen'
import type {Lti1p3RegistrationOverlayStore} from '../Lti1p3RegistrationOverlayState'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationWizardStep} from '../Lti1p3RegistrationWizardState'
import {useOverlayStore} from '../hooks/useOverlayStore'

export type ReviewScreenWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
  transitionTo: (step: Lti1p3RegistrationWizardStep) => void
}

export const ReviewScreenWrapper = ({
  overlayStore,
  internalConfig,
  transitionTo,
}: ReviewScreenWrapperProps) => {
  const [state] = useOverlayStore(overlayStore)
  const placements = state.placements.placements ?? []
  const scopes = state.permissions.scopes ?? []
  const privacyLevel = state.data_sharing.privacy_level
  const labels = state.naming.placements
  const iconUrls = state.icons.placements
  const defaultPlacementIconUrls = Object.fromEntries(
    internalConfig.placements.map(placement => [placement.placement, placement.icon_url])
  )
  const name = state.naming.nickname ?? internalConfig.title

  return (
    <ReviewScreen
      launchSettings={{
        customFields: state.launchSettings.customFields?.split('\n').filter(f => !!f),
        redirectUris: state.launchSettings.redirectURIs?.split('\n'),
        defaultTargetLinkUri: state.launchSettings.targetLinkURI,
        oidcInitiationUrl: state.launchSettings.openIDConnectInitiationURL,
        jwkMethod: state.launchSettings.JwkMethod ?? 'public_jwk_url',
        jwkUrl: state.launchSettings.JwkURL,
        jwk: state.launchSettings.Jwk,
        domain: state.launchSettings.domain,
      }}
      placements={placements}
      scopes={scopes}
      privacyLevel={privacyLevel}
      labels={labels}
      iconUrls={iconUrls}
      defaultPlacementIconUrls={defaultPlacementIconUrls}
      defaultIconUrl={internalConfig.launch_settings?.icon_url}
      nickname={name}
      onEditLaunchSettings={() => transitionTo('LaunchSettings')}
      onEditPlacements={() => transitionTo('Placements')}
      onEditNaming={() => transitionTo('Naming')}
      onEditScopes={() => transitionTo('Permissions')}
      onEditIconUrls={() => transitionTo('Icons')}
      onEditPrivacyLevel={() => transitionTo('DataSharing')}
    />
  )
}
