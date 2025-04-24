/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {LtiPlacement, LtiPlacementWithIcon} from '../model/LtiPlacement'
import {Lti1p3RegistrationOverlayState} from './Lti1p3RegistrationOverlayState'
import {useScope as createI18nScope} from '@canvas/i18n'
import {isValidHttpUrl} from '../../common/lib/validators/isValidHttpUrl'
import {isValidDomainName} from '../../common/lib/validators/isValidDomainName'
import type {FormMessage} from '@instructure/ui-form-field'
import {ZPublicJwk} from '../model/internal_lti_configuration/PublicJwk'

const I18n = createI18nScope('lti_registrations')

type IconUriField = Required<{
  [Placement in keyof Lti1p3RegistrationOverlayState['icons']['placements']]: `icon_uri_${Placement}`
}>[LtiPlacementWithIcon]

type OverrideUriField = Required<{
  [Placement in keyof Lti1p3RegistrationOverlayState['override_uris']['placements']]: `override_uri_${Placement}`
}>[LtiPlacement]

export type Lti1p3RegistrationOverlayStateErrorField =
  | keyof Lti1p3RegistrationOverlayState['launchSettings']
  | IconUriField
  | OverrideUriField

export type Lti1p3RegistrationOverlayStateError = {
  field: Lti1p3RegistrationOverlayStateErrorField
} & FormMessage

/**
 * Returns a unique id for the input field associated with the given field
 * which allows for the input that is associated with the error message to be found
 * and focused on when an attempt is made to save the form with errors.
 * @param field
 * @returns
 */
export const getInputIdForField = <K extends Lti1p3RegistrationOverlayStateErrorField>(
  field: K,
): `reg-overlay-field-${K}` => {
  return `reg-overlay-field-${field}`
}

export const validateUrl = <K extends string>(field: K, url: string | undefined) =>
  url && url.trim() !== '' && !isValidHttpUrl(url)
    ? [{text: I18n.t('Invalid URL'), type: 'error' as const, field}]
    : []

/**
 * Validates the entire Lti1p3RegistrationOverlayState object and returns an
 * array of errors, if any are found.
 * @param state
 * @returns
 */
export const validateLti1p3RegistrationOverlayState = (
  state: Lti1p3RegistrationOverlayState,
): Lti1p3RegistrationOverlayStateError[] => {
  return [
    ...validateLaunchSettings(state.launchSettings),
    ...validateOverrideUris(state.override_uris),
    ...validateIconUris(state.icons),
  ]
}

export const validateOverrideUris = (
  overrideUris: Lti1p3RegistrationOverlayState['override_uris'],
): Lti1p3RegistrationOverlayStateError[] => {
  const placements = Object.keys(overrideUris.placements) as LtiPlacement[]
  return placements.flatMap(placement =>
    validateUrl(`override_uri_${placement}`, overrideUris.placements[placement]?.uri),
  )
}

export const validateIconUris = (
  iconUris: Lti1p3RegistrationOverlayState['icons'],
): Lti1p3RegistrationOverlayStateError[] => {
  const placements = Object.keys(iconUris.placements) as LtiPlacementWithIcon[]
  return placements
    .sort()
    .flatMap(placement => validateUrl(`icon_uri_${placement}`, iconUris.placements[placement]))
}

export const validateLaunchSettings = (
  launchSettings: Lti1p3RegistrationOverlayState['launchSettings'],
): Lti1p3RegistrationOverlayStateError[] => {
  return [
    ...validateRedirectUris(launchSettings.redirectURIs),
    ...validateTargetLinkURI(launchSettings.targetLinkURI),
    ...validateOpenIDConnectInitiationURL(launchSettings.openIDConnectInitiationURL),
    ...validateJwkSettings(launchSettings.Jwk, launchSettings.JwkMethod, launchSettings.JwkURL),
    ...validateDomain(launchSettings.domain),
    ...validateCustomFields(launchSettings.customFields),
  ]
}

export const validateRedirectUris = (
  redirectURIs?: string,
): Lti1p3RegistrationOverlayStateError[] => {
  const uris = redirectURIs?.trim().split('\n') ?? []
  if (uris.length < 1) {
    return [{text: I18n.t('At least one required'), type: 'error', field: 'redirectURIs'}]
  } else if (uris.every(isValidHttpUrl)) {
    return []
  } else {
    return [{text: I18n.t('Invalid URL'), type: 'error', field: 'redirectURIs'}]
  }
}

export const validateTargetLinkURI = (
  targetLinkURI?: string | undefined,
): Lti1p3RegistrationOverlayStateError[] => {
  if (!targetLinkURI) {
    return [{text: I18n.t('Required'), type: 'error', field: 'targetLinkURI'}]
  } else if (!isValidHttpUrl(targetLinkURI)) {
    return [{text: I18n.t('Invalid URL'), type: 'error', field: 'targetLinkURI'}]
  } else {
    return []
  }
}

export const validateOpenIDConnectInitiationURL = (
  openIDConnectInitiationURL?: string,
): Lti1p3RegistrationOverlayStateError[] => {
  if (!openIDConnectInitiationURL) {
    return [{text: I18n.t('Required'), type: 'error', field: 'openIDConnectInitiationURL'}]
  } else if (!isValidHttpUrl(openIDConnectInitiationURL)) {
    return [{text: I18n.t('Invalid URL'), type: 'error', field: 'openIDConnectInitiationURL'}]
  } else {
    return []
  }
}

export const validateJwkSettings = (
  jwk: string | undefined,
  jwkMethod: 'public_jwk' | 'public_jwk_url' | undefined,
  jwkURL: string | undefined,
): Lti1p3RegistrationOverlayStateError[] => {
  if (jwkMethod === 'public_jwk') {
    if (!jwk) {
      return [{text: I18n.t('Required'), type: 'error', field: 'Jwk'}]
    } else {
      try {
        return ZPublicJwk.parse(JSON.parse(jwk))
          ? []
          : [{text: I18n.t('Invalid JWK'), type: 'error', field: 'Jwk'}]
      } catch {
        return [{text: I18n.t('Invalid JWK'), type: 'error', field: 'Jwk'}]
      }
    }
  } else if (jwkMethod === 'public_jwk_url') {
    if (!jwkURL) {
      return [{text: I18n.t('Required'), type: 'error', field: 'JwkURL'}]
    } else if (!isValidHttpUrl(jwkURL)) {
      return [{text: I18n.t('Invalid URL'), type: 'error', field: 'JwkURL'}]
    }
    return []
  } else {
    return []
  }
}

export const validateDomain = (domain?: string): Lti1p3RegistrationOverlayStateError[] => {
  if (domain && !isValidDomainName(domain)) {
    return [
      {
        text: I18n.t(
          'Invalid Domain. Please ensure the domain does not start with http:// or https://.',
        ),
        type: 'error',
        field: 'domain',
      },
    ]
  } else {
    return []
  }
}

export const validateCustomFields = (
  customFields?: string,
): Lti1p3RegistrationOverlayStateError[] => {
  if (!customFields || customFields.trim() === '') {
    return []
  } else if (
    customFields
      .split('\n')
      .map(s => s.trim())
      .filter(s => s.length > 0)
      .every(s => s.match(/.+=.+$/))
  ) {
    return []
  } else {
    return [{text: I18n.t('Invalid Format'), type: 'error', field: 'customFields'}]
  }
}
