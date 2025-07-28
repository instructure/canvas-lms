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
import type {Lti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationWizardStep} from '../Lti1p3RegistrationWizardState'
import {toUndefined} from '../../../common/lib/toUndefined'
import {getDefaultPlacementTextFromConfig} from './helpers'

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
  const {state} = overlayStore()
  const placements = state.placements.placements ?? []
  const scopes = state.permissions.scopes ?? []
  const privacyLevel =
    state.data_sharing.privacy_level ?? internalConfig.privacy_level ?? 'anonymous'

  const labels = Object.fromEntries(
    (state.placements.placements || []).map(placement => [
      placement,
      state.naming.placements[placement] ??
        getDefaultPlacementTextFromConfig(placement, internalConfig),
    ]),
  )
  const iconUrls = state.icons.placements
  const defaultPlacementIconUrls = Object.fromEntries(
    internalConfig.placements.map(placement => [placement.placement, placement.icon_url]),
  )
  const name = state.naming.nickname

  const description = state.naming.description ?? toUndefined(internalConfig.description)

  const jwkValue =
    state.launchSettings.Jwk ??
    (internalConfig.public_jwk ? JSON.stringify(internalConfig.public_jwk) : undefined)

  const customFieldsValue =
    state.launchSettings.customFields?.split('\n').filter(f => !!f) ??
    (internalConfig.custom_fields
      ? Object.entries(internalConfig.custom_fields).map(([key, value]) => `${key}=${value}`)
      : undefined)

  return (
    <ReviewScreen
      launchSettings={{
        customFields: customFieldsValue,
        redirectUris:
          state.launchSettings.redirectURIs?.split('\n') ??
          toUndefined(internalConfig.redirect_uris),
        defaultTargetLinkUri:
          state.launchSettings.targetLinkURI ?? toUndefined(internalConfig.target_link_uri),
        oidcInitiationUrl:
          state.launchSettings.openIDConnectInitiationURL ??
          toUndefined(internalConfig.oidc_initiation_url),
        jwkMethod: state.launchSettings.JwkMethod ?? 'public_jwk_url',
        jwkUrl: state.launchSettings.JwkURL ?? toUndefined(internalConfig.public_jwk_url),
        jwk: jwkValue,
        domain: state.launchSettings.domain ?? toUndefined(internalConfig.domain),
      }}
      description={description}
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
