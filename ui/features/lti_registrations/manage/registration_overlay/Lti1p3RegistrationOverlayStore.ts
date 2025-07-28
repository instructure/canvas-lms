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

import type {LtiMessageType} from '../model/LtiMessageType'
import {type LtiPlacement, type LtiPlacementWithIcon} from '../model/LtiPlacement'
import type {LtiPrivacyLevel} from '../model/LtiPrivacyLevel'
import type {LtiScope} from '@canvas/lti/model/LtiScope'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {create} from 'zustand'
import type {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import {initialOverlayStateFromInternalConfig} from './Lti1p3RegistrationOverlayStateHelpers'
import {filterEmptyString} from '../../common/lib/filterEmptyString'
import {Lti1p3RegistrationOverlayState} from './Lti1p3RegistrationOverlayState'

export type PlacementLabelOverride = string
export type IconUrlOverride = string

export interface Lti1p3RegistrationOverlayActions {
  setDirty: (dirty: boolean) => void
  setHasSubmitted: (hasSubmitted: boolean) => void
  setRedirectURIs: (redirectURIs: string) => void
  setDefaultTargetLinkURI: (targetLinkURI: string) => void
  setOIDCInitiationURI: (oidcInitiationURI: string) => void
  setJwkMethod: (
    jwkMethod: Required<Lti1p3RegistrationOverlayState['launchSettings']['JwkMethod']>,
  ) => void
  setJwkURL: (jwkURL: string) => void
  setJwk: (jwk: string) => void
  setDomain: (domain: string) => void
  setCustomFields: (customFields: string) => void
  setOverrideURI: (placement: LtiPlacement, uri: string) => void
  setPlacementIconUrl: (placement: LtiPlacementWithIcon, iconUrl: string) => void
  setMessageType: (placement: LtiPlacement, messageType: LtiMessageType) => void
  setAdminNickname: (nickname: string) => void
  setDescription: (description: string) => void
  setPlacementLabel: (placement: LtiPlacement, name: string) => void
  toggleScope: (scope: LtiScope) => void
  setPrivacyLevel: (privacyLevel: LtiPrivacyLevel) => void
  togglePlacement: (placement: LtiPlacement) => void
  toggleCourseNavigationDefaultDisabled: () => void
}

const updateState =
  (f: (state: Lti1p3RegistrationOverlayState) => Lti1p3RegistrationOverlayState) =>
  (fullState: {state: Lti1p3RegistrationOverlayState}): {state: Lti1p3RegistrationOverlayState} =>
    stateFor({
      ...f(fullState.state),
      dirty: true,
    })

const stateFor = (state: Lti1p3RegistrationOverlayState) => ({state})

const updateLaunchSetting = <K extends keyof Lti1p3RegistrationOverlayState['launchSettings']>(
  key: K,
  value: Lti1p3RegistrationOverlayState['launchSettings'][K],
) =>
  updateState(state => ({
    ...state,
    launchSettings: {
      ...state.launchSettings,
      [key]: value,
    },
  }))

const updateOverrideURI = (placement: LtiPlacement, uri: string) => {
  return updateState(state => {
    return {
      ...state,
      override_uris: {
        ...state.override_uris,
        placements: {
          ...state.override_uris.placements,
          [placement]: {
            ...state.override_uris.placements[placement],
            uri,
          },
        },
      },
    }
  })
}

const updateMessageType = (placement: LtiPlacement, messageType: LtiMessageType) => {
  return updateState(state => {
    return {
      ...state,
      override_uris: {
        ...state.override_uris,
        placements: {
          ...state.override_uris.placements,
          [placement]: {
            ...state.override_uris.placements[placement],
            message_type: messageType,
          },
        },
      },
    }
  })
}

export const createLti1p3RegistrationOverlayStore = (
  internalConfig: InternalLtiConfiguration,
  adminNickname?: string,
  existingOverlay?: LtiConfigurationOverlay,
) =>
  create<{state: Lti1p3RegistrationOverlayState} & Lti1p3RegistrationOverlayActions>(set => ({
    state: initialOverlayStateFromInternalConfig(internalConfig, adminNickname, existingOverlay),
    setDirty: dirty => set(s => ({...set, state: {...s.state, dirty}})),
    setHasSubmitted: hasSubmitted => set(s => ({...set, state: {...s.state, hasSubmitted}})),
    setRedirectURIs: redirectURIs =>
      set(updateLaunchSetting('redirectURIs', filterEmptyString(redirectURIs))),
    setDefaultTargetLinkURI: targetLinkURI =>
      set(updateLaunchSetting('targetLinkURI', filterEmptyString(targetLinkURI))),
    setOIDCInitiationURI: oidcInitiationURI =>
      set(updateLaunchSetting('openIDConnectInitiationURL', filterEmptyString(oidcInitiationURI))),
    setJwkURL: jwkURL => set(updateLaunchSetting('JwkURL', filterEmptyString(jwkURL))),
    setJwk: jwk => set(updateLaunchSetting('Jwk', filterEmptyString(jwk))),
    setJwkMethod: jwkMethod => set(updateLaunchSetting('JwkMethod', jwkMethod)),
    setDomain: domain => set(updateLaunchSetting('domain', filterEmptyString(domain))),
    setCustomFields: customFields =>
      set(updateLaunchSetting('customFields', filterEmptyString(customFields))),
    setOverrideURI: (placement, uri) => set(updateOverrideURI(placement, uri)),
    setMessageType: (placement, messageType) => set(updateMessageType(placement, messageType)),
    setAdminNickname: nickname =>
      set(updateState(state => ({...state, naming: {...state.naming, nickname}}))),
    setDescription: description =>
      set(
        updateState(state => ({
          ...state,
          naming: {...state.naming, description: filterEmptyString(description)},
        })),
      ),
    setPlacementLabel: (placement, name) =>
      set(
        updateState(state => ({
          ...state,
          naming: {
            ...state.naming,
            placements: {
              ...state.naming.placements,
              [placement]: filterEmptyString(name),
            },
          },
        })),
      ),
    toggleScope: scope => {
      set(
        updateState(state => {
          let updatedScopes = state.permissions.scopes

          if (updatedScopes?.includes(scope)) {
            updatedScopes = updatedScopes.filter(s => s !== scope)
          } else {
            updatedScopes = [...(updatedScopes ?? []), scope]
          }
          return {
            ...state,
            permissions: {
              ...state.permissions,
              scopes: updatedScopes,
            },
          }
        }),
      )
    },
    setPrivacyLevel: privacyLevel =>
      set(
        updateState(state => ({
          ...state,
          data_sharing: {
            ...state.data_sharing,
            privacy_level: privacyLevel,
          },
        })),
      ),
    toggleCourseNavigationDefaultDisabled: () => {
      set(
        updateState(state => {
          return {
            ...state,
            placements: {
              ...state.placements,
              courseNavigationDefaultDisabled: !state.placements.courseNavigationDefaultDisabled,
            },
          }
        }),
      )
    },
    togglePlacement: placement => {
      set(
        updateState(state => {
          let updatedPlacements = state.placements.placements

          if (updatedPlacements?.includes(placement)) {
            updatedPlacements = updatedPlacements.filter(p => p !== placement)
          } else {
            updatedPlacements = [...(updatedPlacements ?? []), placement]
          }

          return {
            ...state,
            placements: {
              ...state.placements,
              placements: updatedPlacements,
            },
          }
        }),
      )
    },
    setPlacementIconUrl: (placement, iconUrl) => {
      set(
        updateState(state => {
          return {
            ...state,
            icons: {
              ...state.icons,
              placements: {
                ...state.icons.placements,
                [placement]: filterEmptyString(iconUrl),
              },
            },
          }
        }),
      )
    },
  }))

export type Lti1p3RegistrationOverlayStore = ReturnType<typeof createLti1p3RegistrationOverlayStore>
