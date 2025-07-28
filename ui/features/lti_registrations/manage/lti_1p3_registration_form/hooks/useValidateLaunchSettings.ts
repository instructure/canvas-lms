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

import React, {useMemo} from 'react'
import type {FormMessage} from '@instructure/ui-form-field'
import {useScope as createI18nScope} from '@canvas/i18n'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import {isValidDomainName} from '../../../common/lib/validators/isValidDomainName'
import {ZPublicJwk} from '../../model/internal_lti_configuration/PublicJwk'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {
  validateCustomFields,
  validateDomain,
  validateJwkSettings,
  validateOpenIDConnectInitiationURL,
  validateRedirectUris,
  validateTargetLinkURI,
} from '../../registration_overlay/validateLti1p3RegistrationOverlayState'

const I18n = createI18nScope('lti_registrations')

export type LaunchSettingsValidationMessages = {
  redirectUrisMessages: FormMessage[]
  targetLinkURIMessages: FormMessage[]
  openIDConnectInitiationURLMessages: FormMessage[]
  jwkMessages: FormMessage[]
  domainMessages: FormMessage[]
  customFieldsMessages: FormMessage[]
}

export const useValidateLaunchSettings = (
  launchSettings: Partial<{
    redirectURIs: string
    targetLinkURI: string
    openIDConnectInitiationURL: string
    JwkMethod: 'public_jwk_url' | 'public_jwk'
    JwkURL: string
    Jwk: string
    domain: string
    customFields: string
  }>,
): LaunchSettingsValidationMessages => {
  const redirectUrisMessages: FormMessage[] = useMemo(
    () => validateRedirectUris(launchSettings.redirectURIs),
    [launchSettings.redirectURIs],
  )

  const targetLinkURIMessages: FormMessage[] = useMemo(
    () => validateTargetLinkURI(launchSettings.targetLinkURI),
    [launchSettings.targetLinkURI],
  )

  const openIDConnectInitiationURLMessages: FormMessage[] = useMemo(
    () => validateOpenIDConnectInitiationURL(launchSettings.openIDConnectInitiationURL),
    [launchSettings.openIDConnectInitiationURL],
  )

  const jwkMessages: FormMessage[] = useMemo(
    () => validateJwkSettings(launchSettings.Jwk, launchSettings.JwkMethod, launchSettings.JwkURL),
    [launchSettings.Jwk, launchSettings.JwkMethod, launchSettings.JwkURL],
  )

  const domainMessages: FormMessage[] = useMemo(
    () => validateDomain(launchSettings.domain),
    [launchSettings.domain],
  )

  const customFieldsMessages: FormMessage[] = React.useMemo(
    () => validateCustomFields(launchSettings.customFields),
    [launchSettings.customFields],
  )

  return {
    redirectUrisMessages,
    targetLinkURIMessages,
    openIDConnectInitiationURLMessages,
    jwkMessages,
    domainMessages,
    customFieldsMessages,
  }
}
