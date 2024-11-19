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

import type {StoreApi} from 'zustand'
import type {LtiMessageType} from '../model/LtiMessageType'
import {
  isLtiPlacementWithIcon,
  type LtiPlacement,
  type LtiPlacementWithIcon,
} from '../model/LtiPlacement'
import type {LtiPrivacyLevel} from '../model/LtiPrivacyLevel'
import type {LtiScope} from '@canvas/lti/model/LtiScope'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import create from 'zustand'
import type {
  LtiConfigurationOverlay,
  LtiPlacementOverlay,
} from '../model/internal_lti_configuration/LtiConfigurationOverlay'

type PlacementLabelOverride = string
type IconUrlOverride = string

export type Lti1p3RegistrationOverlayState = {
  launchSettings: Partial<{
    redirectURIs: string
    targetLinkURI: string
    openIDConnectInitiationURL: string
    JwkMethod: 'public_jwk_url' | 'public_jwk'
    JwkURL: string
    Jwk: string
    domain: string
    customFields: string
  }>
  permissions: {
    scopes?: LtiScope[]
  }
  data_sharing: {
    privacy_level?: LtiPrivacyLevel
  }
  placements: {
    placements?: LtiPlacement[]
    courseNavigationDefaultDisabled?: boolean
  }
  override_uris: {
    placements: Partial<
      Record<
        LtiPlacement,
        {
          message_type?: LtiMessageType
          uri?: string
        }
      >
    >
  }
  naming: {
    nickname?: string
    description?: string
    notes?: string
    placements: Partial<Record<LtiPlacement, PlacementLabelOverride>>
  }
  icons: {
    placements: Partial<Record<LtiPlacementWithIcon, IconUrlOverride>>
  }
}

export interface Lti1p3RegistrationOverlayActions {
  setRedirectURIs: (redirectURIs: string) => void
  setDefaultTargetLinkURI: (targetLinkURI: string) => void
  setOIDCInitiationURI: (oidcInitiationURI: string) => void
  setJwkMethod: (
    jwkMethod: Required<Lti1p3RegistrationOverlayState['launchSettings']['JwkMethod']>
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

export type Lti1p3RegistrationOverlayStore = StoreApi<
  {
    state: Lti1p3RegistrationOverlayState
  } & Lti1p3RegistrationOverlayActions
>

const updateState =
  (f: (state: Lti1p3RegistrationOverlayState) => Lti1p3RegistrationOverlayState) =>
  (fullState: {state: Lti1p3RegistrationOverlayState}): {state: Lti1p3RegistrationOverlayState} =>
    stateFor(f(fullState.state))

const stateFor = (state: Lti1p3RegistrationOverlayState) => ({state})

const updateLaunchSetting = <K extends keyof Lti1p3RegistrationOverlayState['launchSettings']>(
  key: K,
  value: Lti1p3RegistrationOverlayState['launchSettings'][K]
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
            messageType,
          },
        },
      },
    }
  })
}

/**
 * Converts an Lti1p3RegistrationOverlayState to an LtiConfigurationOverlay, with an optionally provided
 * InternalLtiConfiguration to determine which placements and scopes are disabled.
 *
 * Note that all fields are assumed to be valid, so no validation is performed.
 *
 * @param state The Lti1p3RegistrationOverlayState to convert
 * @param internalConfig The InternalLtiConfiguration to use to determine which placements and scopes are disabled
 * @returns The LtiConfigurationOverlay
 */
export const convertToLtiConfigurationOverlay = (
  state: Lti1p3RegistrationOverlayState,
  internalConfig?: InternalLtiConfiguration
): LtiConfigurationOverlay => {
  const custom_fields = state.launchSettings.customFields
    ? Object.fromEntries(
        state.launchSettings.customFields
          .split('\n')
          .filter(f => !!f)
          .map(customField => {
            const [key, value] = customField.split('=')
            return [key, value]
          })
      )
    : undefined
  const disabled_placements = internalConfig
    ? internalConfig.placements
        .map(p => p.placement)
        .filter(p => !state.placements.placements?.includes(p))
    : undefined

  const disabled_scopes = internalConfig
    ? internalConfig.scopes.filter(s => !state.permissions.scopes?.includes(s))
    : undefined
  const placements = state.placements.placements?.reduce((acc, placement) => {
    return {
      ...acc,
      [placement]: {
        text: state.naming.placements[placement],
        target_link_uri: state.override_uris.placements[placement]?.uri,
        message_type: state.override_uris.placements[placement]?.message_type,
        // We don't currently let user's modify this setting in the UI
        launch_height: undefined,
        launch_wdith: undefined,
        icon_url: state.icons.placements[placement as LtiPlacementWithIcon],
        default:
          placement === 'course_navigation' && state.placements.courseNavigationDefaultDisabled
            ? 'disabled'
            : 'enabled',
      },
    }
  }, {})

  return {
    title: state.naming.nickname,
    description: state.naming.description,
    custom_fields,
    target_link_uri: state.launchSettings.targetLinkURI,
    oidc_initiation_url: state.launchSettings.openIDConnectInitiationURL,
    redirect_uris: state.launchSettings.redirectURIs?.split('\n'),
    public_jwk: state.launchSettings.Jwk ? JSON.parse(state.launchSettings.Jwk) : undefined,
    public_jwk_url: state.launchSettings.JwkURL,
    disabled_scopes,
    domain: state.launchSettings.domain,
    privacy_level: state.data_sharing.privacy_level,
    disabled_placements,
    placements,
    scopes: state.permissions.scopes,
  }
}

export const createLti1p3RegistrationOverlayStore = (internalConfig: InternalLtiConfiguration) =>
  create<{state: Lti1p3RegistrationOverlayState} & Lti1p3RegistrationOverlayActions>(set => ({
    state: initialOverlayStateFromInternalConfig(internalConfig),
    setRedirectURIs: redirectURIs => set(updateLaunchSetting('redirectURIs', redirectURIs)),
    setDefaultTargetLinkURI: targetLinkURI =>
      set(updateLaunchSetting('targetLinkURI', targetLinkURI)),
    setOIDCInitiationURI: oidcInitiationURI =>
      set(updateLaunchSetting('openIDConnectInitiationURL', oidcInitiationURI)),
    setJwkURL: jwkURL => set(updateLaunchSetting('JwkURL', jwkURL)),
    setJwk: jwk => set(updateLaunchSetting('Jwk', jwk)),
    setJwkMethod: jwkMethod => set(updateLaunchSetting('JwkMethod', jwkMethod)),
    setDomain: domain => set(updateLaunchSetting('domain', domain)),
    setCustomFields: customFields => set(updateLaunchSetting('customFields', customFields)),
    setOverrideURI: (placement, uri) => set(updateOverrideURI(placement, uri)),
    setMessageType: (placement, messageType) => set(updateMessageType(placement, messageType)),
    setAdminNickname: nickname =>
      set(updateState(state => ({...state, naming: {...state.naming, nickname}}))),
    setDescription: description =>
      set(updateState(state => ({...state, naming: {...state.naming, description}}))),
    setPlacementLabel: (placement, name) =>
      set(
        updateState(state => ({
          ...state,
          naming: {
            ...state.naming,
            placements: {
              ...state.naming.placements,
              [placement]: name,
            },
          },
        }))
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
        })
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
        }))
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
        })
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
        })
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
                [placement]: iconUrl,
              },
            },
          }
        })
      )
    },
  }))

const initialOverlayStateFromInternalConfig = (
  internalConfig: InternalLtiConfiguration
): Lti1p3RegistrationOverlayState => {
  return {
    launchSettings: {
      redirectURIs: internalConfig.redirect_uris?.join('\n'),
      targetLinkURI: internalConfig.target_link_uri,
      openIDConnectInitiationURL: internalConfig.oidc_initiation_url,
      JwkMethod: internalConfig.public_jwk_url ? 'public_jwk_url' : 'public_jwk',
      JwkURL: internalConfig.public_jwk_url === null ? undefined : internalConfig.public_jwk_url,
      Jwk: JSON.stringify(internalConfig.public_jwk),
      domain: internalConfig.domain === null ? undefined : internalConfig.domain,
      customFields: internalConfig.custom_fields
        ? Object.entries(internalConfig.custom_fields).reduce((acc, [key, value]) => {
            return acc + `${key}=${value}\n`
          }, '')
        : undefined,
    },
    permissions: {
      scopes: internalConfig.scopes,
    },
    data_sharing: {
      privacy_level:
        internalConfig.privacy_level === null ? undefined : internalConfig.privacy_level,
    },
    placements: {
      placements: internalConfig.placements.map(p => p.placement) ?? [],
      courseNavigationDefaultDisabled:
        internalConfig.placements.find(p => p.placement === 'course_navigation')?.default ===
        'disabled',
    },
    override_uris: {
      placements: internalConfig.placements.reduce<
        Record<LtiPlacement, {message_type: LtiMessageType; uri: string}>
      >((acc, p) => {
        acc[p.placement] = {
          message_type: p.message_type ?? 'LtiResourceLinkRequest',
          uri: p.target_link_uri ?? p.url ?? internalConfig.target_link_uri,
        }
        return acc
      }, {} as Record<LtiPlacement, {message_type: LtiMessageType; uri: string}>),
    },
    naming: {
      nickname: internalConfig.title,
      description: '',
      notes: '',
      placements:
        internalConfig.placements.reduce((acc, p) => {
          acc[p.placement] = p.text ?? internalConfig.title
          return acc
        }, {} as Record<LtiPlacement, string>) ?? [],
    },
    icons: {
      placements: internalConfig.placements.reduce((acc, p) => {
        if (isLtiPlacementWithIcon(p.placement)) {
          acc[p.placement] = p.icon_url
          return acc
        }
        return acc
      }, {} as Partial<Record<LtiPlacementWithIcon, string>>),
    },
  }
}
