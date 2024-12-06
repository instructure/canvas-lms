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
import {useScope as useI18nScope} from '@canvas/i18n'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import {isValidDomainName} from '../../../common/lib/validators/isValidDomainName'
import {ZPublicJwk} from '../../model/internal_lti_configuration/PublicJwk'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'

const I18n = useI18nScope('lti_registrations')

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
  internalConfig: InternalLtiConfiguration
): LaunchSettingsValidationMessages => {
  const redirectUrisMessages: FormMessage[] = useMemo(() => {
    const uris = launchSettings.redirectURIs?.trim().split('\n') ?? []
    if (uris.length < 1) {
      return [{text: I18n.t('At least one required'), type: 'error'}]
    } else if (uris.every(isValidHttpUrl)) {
      return []
    } else {
      return [{text: I18n.t('Invalid URL'), type: 'error'}]
    }
  }, [launchSettings.redirectURIs])

  const targetLinkURIMessages: FormMessage[] = useMemo(() => {
    const value = launchSettings.targetLinkURI ?? internalConfig.target_link_uri
    if (!value) {
      return [{text: I18n.t('Required'), type: 'error'}]
    } else if (!isValidHttpUrl(value)) {
      return [{text: I18n.t('Invalid URL'), type: 'error'}]
    } else {
      return []
    }
  }, [launchSettings.targetLinkURI, internalConfig.target_link_uri])

  const openIDConnectInitiationURLMessages: FormMessage[] = useMemo(() => {
    if (isValidHttpUrl(launchSettings.openIDConnectInitiationURL || '')) {
      return []
    }
    return [{text: I18n.t('Invalid URL'), type: 'error'}]
  }, [launchSettings.openIDConnectInitiationURL])

  const jwkMessages: FormMessage[] = useMemo(() => {
    if (launchSettings.JwkMethod === 'public_jwk') {
      const jwk =
        launchSettings.Jwk ??
        (internalConfig.public_jwk ? JSON.stringify(internalConfig.public_jwk, null, 2) : undefined)
      if (!jwk) {
        return [{text: I18n.t('Required'), type: 'error'}]
      } else {
        try {
          return ZPublicJwk.parse(JSON.parse(jwk))
            ? []
            : [{text: I18n.t('Invalid JWK'), type: 'error'}]
        } catch {
          return [{text: I18n.t('Invalid JWK'), type: 'error'}]
        }
      }
    } else if (launchSettings.JwkMethod === 'public_jwk_url') {
      const jwkUrl = launchSettings.JwkURL ?? internalConfig.public_jwk_url
      if (!jwkUrl) {
        return [{text: I18n.t('Required'), type: 'error'}]
      } else if (!isValidHttpUrl(jwkUrl)) {
        return [{text: I18n.t('Invalid URL'), type: 'error'}]
      }
      return []
    } else {
      return []
    }
  }, [
    internalConfig.public_jwk,
    internalConfig.public_jwk_url,
    launchSettings.Jwk,
    launchSettings.JwkMethod,
    launchSettings.JwkURL,
  ])

  const domainMessages: FormMessage[] = useMemo(() => {
    const value = launchSettings.domain ?? internalConfig.domain
    if (value && !isValidDomainName(value)) {
      return [
        {
          text: I18n.t(
            'Invalid Domain. Please ensure the domain does not start with http:// or https://.'
          ),
          type: 'error',
        },
      ]
    } else {
      return []
    }
  }, [launchSettings.domain, internalConfig.domain])

  const customFieldsMessages: FormMessage[] = React.useMemo(() => {
    const customFields =
      launchSettings.customFields ??
      (internalConfig.custom_fields
        ? Object.entries(internalConfig.custom_fields)
            .map(([k, v]) => `${k}=${v}`)
            .join('\n')
        : undefined)
    if (!customFields || customFields.length === 0) {
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
      return [{text: I18n.t('Invalid Format'), type: 'error'}]
    }
  }, [launchSettings.customFields, internalConfig.custom_fields])

  return {
    redirectUrisMessages,
    targetLinkURIMessages,
    openIDConnectInitiationURLMessages,
    jwkMessages,
    domainMessages,
    customFieldsMessages,
  }
}
