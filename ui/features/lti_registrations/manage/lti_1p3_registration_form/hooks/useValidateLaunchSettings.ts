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
import type {FormMessage} from '@instructure/ui-form-field'
import {useScope as useI18nScope} from '@canvas/i18n'
import {isValidHttpUrl} from '../../../common/lib/validators/isValidHttpUrl'
import {isValidDomainName} from '../../../common/lib/validators/isValidDomainName'
import {ZPublicJwk} from '../../model/internal_lti_configuration/PublicJwk'
import type {Lti1p3RegistrationOverlayState} from '../Lti1p3RegistrationOverlayState'

const I18n = useI18nScope('lti_registrations')

export const useValidateLaunchSettings = (
  launchSettings: Lti1p3RegistrationOverlayState['launchSettings']
) => {
  const redirectUrisMessages: FormMessage[] = React.useMemo(() => {
    if (
      !launchSettings.redirectURIs ||
      launchSettings.redirectURIs.split('\n').every(isValidHttpUrl)
    ) {
      return []
    } else {
      return [{text: I18n.t('Invalid URL'), type: 'error'}]
    }
  }, [launchSettings.redirectURIs])

  const targetLinkURIMessages: FormMessage[] = React.useMemo(() => {
    if (!launchSettings.targetLinkURI) {
      return [{text: I18n.t('Required'), type: 'error'}]
    } else if (!isValidHttpUrl(launchSettings.targetLinkURI)) {
      return [{text: I18n.t('Invalid URL'), type: 'error'}]
    } else {
      return []
    }
  }, [launchSettings.targetLinkURI])

  const openIDConnectInitiationURLMessages: FormMessage[] = React.useMemo(() => {
    if (isValidHttpUrl(launchSettings.openIDConnectInitiationURL!)) {
      return []
    }
    return [{text: I18n.t('Invalid URL'), type: 'error'}]
  }, [launchSettings.openIDConnectInitiationURL])

  const jwkMessages: FormMessage[] = React.useMemo(() => {
    if (launchSettings.JwkMethod === 'public_jwk') {
      if (!launchSettings.Jwk) {
        return [{text: I18n.t('Required'), type: 'error'}]
      } else {
        try {
          return ZPublicJwk.parse(JSON.parse(launchSettings.Jwk))
            ? []
            : [{text: I18n.t('Invalid JWK'), type: 'error'}]
        } catch {
          return [{text: I18n.t('Invalid JWK'), type: 'error'}]
        }
      }
    } else if (launchSettings.JwkMethod === 'public_jwk_url') {
      if (!launchSettings.JwkURL) {
        return [{text: I18n.t('Required'), type: 'error'}]
      } else if (!isValidHttpUrl(launchSettings.JwkURL)) {
        return [{text: I18n.t('Invalid URL'), type: 'error'}]
      }
      return []
    } else {
      return []
    }
  }, [launchSettings.Jwk, launchSettings.JwkMethod, launchSettings.JwkURL])

  const domainMessages: FormMessage[] = React.useMemo(() => {
    if (!launchSettings.domain || launchSettings.domain.length === 0) {
      return []
    } else if (!isValidDomainName(launchSettings.domain)) {
      return [{text: I18n.t('Invalid Domain'), type: 'error'}]
    } else {
      return []
    }
  }, [launchSettings.domain])

  const customFieldsMessages: FormMessage[] = React.useMemo(() => {
    if (!launchSettings.customFields || launchSettings.customFields.length === 0) {
      return []
    } else if (
      launchSettings.customFields
        .split('\n')
        .map(s => s.trim())
        .filter(s => s.length > 0)
        .every(s => s.match(/.+=.+$/))
    ) {
      return []
    } else {
      return [{text: I18n.t('Invalid Format'), type: 'error'}]
    }
  }, [launchSettings.customFields])

  return {
    redirectUrisMessages,
    targetLinkURIMessages,
    openIDConnectInitiationURLMessages,
    jwkMessages,
    domainMessages,
    customFieldsMessages,
  }
}
