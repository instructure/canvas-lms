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
import {compact} from '../../common/lib/compact'
import {toUndefined} from '../../common/lib/toUndefined'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {LtiConfigurationOverlay} from '../model/internal_lti_configuration/LtiConfigurationOverlay'
import type {LtiMessageType} from '../model/LtiMessageType'
import {
  type LtiPlacement,
  isLtiPlacementWithIcon,
  type LtiPlacementWithIcon,
} from '../model/LtiPlacement'
import {type Lti1p3RegistrationOverlayState} from './Lti1p3RegistrationOverlayState'

export const initialOverlayStateFromInternalConfig = (
  internalConfig: InternalLtiConfiguration,
  adminNickname?: string,
  existingOverlay?: LtiConfigurationOverlay,
): Lti1p3RegistrationOverlayState => {
  const placements = internalConfig.placements
    .map(p => p.placement)
    .filter(p => !existingOverlay?.disabled_placements?.includes(p))
    .concat(keys(existingOverlay?.placements))
    .filter((value, index, array) => array.indexOf(value) === index) // unique values

  const courseNavigationDefaultDisabled = existingOverlay?.placements?.course_navigation?.default
    ? existingOverlay.placements.course_navigation.default === 'disabled'
    : internalConfig.placements.find(p => p.placement === 'course_navigation')?.default ===
      'disabled'

  return {
    dirty: false,
    hasSubmitted: false,
    launchSettings: {
      redirectURIs: internalConfig.redirect_uris?.join('\n'),
      targetLinkURI: existingOverlay?.target_link_uri || internalConfig.target_link_uri,
      openIDConnectInitiationURL: internalConfig.oidc_initiation_url,
      JwkMethod: internalConfig.public_jwk_url ? 'public_jwk_url' : 'public_jwk',
      JwkURL: toUndefined(internalConfig.public_jwk_url),
      Jwk: toUndefined(
        internalConfig.public_jwk ? JSON.stringify(internalConfig.public_jwk, null, 2) : undefined,
      ),
      domain: existingOverlay?.domain || toUndefined(internalConfig.domain),
      customFields: formatCustomFields(
        existingOverlay?.custom_fields || internalConfig.custom_fields,
      ),
    },
    permissions: {
      scopes: internalConfig.scopes.filter(s => !existingOverlay?.disabled_scopes?.includes(s)),
    },
    data_sharing: {
      privacy_level: existingOverlay?.privacy_level || toUndefined(internalConfig.privacy_level),
    },
    placements: {
      placements,
      courseNavigationDefaultDisabled,
    },
    override_uris: {
      placements: placements.reduce(
        (acc, p) => {
          acc[p] = {
            message_type:
              existingOverlay?.placements?.[p]?.message_type ||
              internalConfig?.placements.find(i => i.placement === p)?.message_type,
            uri:
              existingOverlay?.placements?.[p]?.target_link_uri ||
              internalConfig?.placements.find(i => i.placement === p)?.target_link_uri,
          }
          return acc
        },
        {} as Record<LtiPlacement, {message_type?: LtiMessageType; uri?: string}>,
      ),
    },
    naming: {
      nickname: adminNickname,
      description: existingOverlay?.description || toUndefined(internalConfig.description),
      placements:
        placements.reduce(
          (acc, p) => {
            acc[p] =
              existingOverlay?.placements?.[p]?.text ||
              internalConfig?.placements.find(i => i.placement === p)?.text
            return acc
          },
          {} as Record<LtiPlacement, string | undefined>,
        ) ?? [],
    },
    icons: {
      placements: placements.reduce(
        (acc, p) => {
          if (isLtiPlacementWithIcon(p)) {
            acc[p] =
              existingOverlay?.placements?.[p]?.icon_url ||
              internalConfig.placements.find(i => i.placement === p)?.icon_url
            return acc
          }
          return acc
        },
        {} as Partial<Record<LtiPlacementWithIcon, string | undefined>>,
      ),
    },
  }
}

/**
 * Converts an Lti1p3RegistrationOverlayState to an LtiConfigurationOverlay, with an optionally provided
 * InternalLtiConfiguration to determine which placements and scopes are disabled.
 *
 * Note that all fields are assumed to be valid, so no validation is performed.
 *
 * @param state The Lti1p3RegistrationOverlayState to convert
 * @param internalConfig The InternalLtiConfiguration to use to determine which placements and scopes are disabled
 * @returns The updated LtiConfigurationOverlay and the InternalLtiConfiguration
 */
export const convertToLtiConfigurationOverlay = (
  state: Lti1p3RegistrationOverlayState,
  internalConfig: InternalLtiConfiguration,
): {overlay: LtiConfigurationOverlay; config: InternalLtiConfiguration} => {
  const placements = state.placements.placements?.reduce((acc, placement) => {
    const internalPlacement = internalConfig.placements.find(p => p.placement === placement)
    const courseNavDefaultValue =
      placement === 'course_navigation'
        ? computeCourseNavDefaultValue(state, internalConfig)
        : undefined

    const placementConfig = compact({
      text:
        state.naming.placements[placement] === internalPlacement?.text
          ? undefined
          : state.naming.placements[placement],
      target_link_uri:
        state.override_uris.placements[placement]?.uri === internalPlacement?.target_link_uri
          ? undefined
          : state.override_uris.placements[placement]?.uri,
      message_type:
        state.override_uris.placements[placement]?.message_type === internalPlacement?.message_type
          ? undefined
          : state.override_uris.placements[placement]?.message_type,
      icon_url:
        state.icons.placements[placement as LtiPlacementWithIcon] === internalPlacement?.icon_url
          ? undefined
          : state.icons.placements[placement as LtiPlacementWithIcon],
      default:
        courseNavDefaultValue === internalPlacement?.default ? undefined : courseNavDefaultValue,
    })
    return {
      ...acc,
      [placement]: placementConfig,
    }
  }, {})

  const disabled_placements = internalConfig
    ? internalConfig.placements
        .map(p => p.placement)
        .filter(p => !state.placements.placements?.includes(p))
    : undefined

  const disabled_scopes = internalConfig.scopes.filter(s => !state.permissions.scopes?.includes(s))

  const newInternalConfig = {
    ...internalConfig,
    scopes: state.permissions.scopes || [],
    redirect_uris: state.launchSettings.redirectURIs?.split('\n'),
    public_jwk:
      state.launchSettings.JwkMethod === 'public_jwk' && state.launchSettings.Jwk
        ? JSON.parse(state.launchSettings.Jwk)
        : undefined,
    public_jwk_url:
      state.launchSettings.JwkMethod === 'public_jwk_url' ? state.launchSettings.JwkURL : null,
    oidc_initiation_url:
      state.launchSettings.openIDConnectInitiationURL || internalConfig.oidc_initiation_url,
  }

  return {
    overlay: compact({
      title: undefined,
      description:
        state.naming.description === internalConfig.description
          ? undefined
          : state.naming.description,
      custom_fields: computeOverlayedCustomFields(state, internalConfig),
      target_link_uri:
        state.launchSettings.targetLinkURI === internalConfig.target_link_uri
          ? undefined
          : state.launchSettings.targetLinkURI,
      disabled_scopes,
      privacy_level:
        state.data_sharing.privacy_level === internalConfig.privacy_level
          ? undefined
          : state.data_sharing.privacy_level,
      disabled_placements,
      placements,
      domain:
        state.launchSettings.domain === internalConfig.domain
          ? undefined
          : state.launchSettings.domain,
      // todo: these undefined fields will all be removed
      oidc_initiation_url: undefined,
      redirect_uris: undefined,
      public_jwk: undefined as any,
      public_jwk_url: undefined,
    }),
    config: newInternalConfig,
  }
}

const computeOverlayedCustomFields = (
  state: Lti1p3RegistrationOverlayState,
  internalConfig: InternalLtiConfiguration,
) => {
  const customFieldsState = state.launchSettings.customFields
    ? Object.fromEntries(
        state.launchSettings.customFields
          .split('\n')
          .filter(f => !!f)
          .map(customField => {
            const [key, value] = customField.split('=')
            return [key, value]
          }),
      )
    : undefined

  return customFieldsState &&
    internalConfig.custom_fields &&
    recordsAreEqual(customFieldsState, internalConfig.custom_fields)
    ? undefined
    : customFieldsState
}

const recordsAreEqual = (a: Record<string, string>, b: Record<string, string>) => {
  const keys = Object.keys(a)
  if (keys.length !== Object.keys(b).length) {
    return false
  }
  return keys.every(key => a[key] === b[key])
}

export const keys = <T>(object?: T): Array<keyof T> => {
  return (object ? Object.keys(object) : []) as Array<keyof T>
}

export const formatCustomFields = (
  customFields: Record<string, string> | null | undefined,
): string | undefined => {
  return customFields
    ? Object.entries(customFields).reduce((acc, [key, value]) => {
        return acc + `${key}=${value}\n`
      }, '')
    : undefined
}

export const computeCourseNavDefaultValue = (
  state: Lti1p3RegistrationOverlayState,
  internalConfig?: InternalLtiConfiguration,
): 'enabled' | 'disabled' | undefined => {
  const courseNavConfig = internalConfig?.placements.find(p => p.placement === 'course_navigation')
  if (typeof state.placements.courseNavigationDefaultDisabled !== 'undefined') {
    const overlayState = state.placements.courseNavigationDefaultDisabled ? 'disabled' : 'enabled'
    return courseNavConfig?.default === overlayState ? undefined : overlayState
  } else {
    return undefined
  }
}
