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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import type {LaunchSettingsDiff as LaunchSettingsDiffType} from '../differ'
import {Diff, DiffList, DiffRecord} from './DiffHelpers'

const I18n = createI18nScope('lti_registrations')

export type LaunchSettingsDiffProps = {
  diff: NonNullable<LaunchSettingsDiffType>
}

/**
 * Display launch settings changes including redirect URIs, target link URI,
 * OIDC URLs, JWK, domain, and custom fields
 */
export const LaunchSettingsDiff: React.FC<LaunchSettingsDiffProps> = ({diff}) => {
  const hasRedirectUriChanges = diff.redirectUris !== null
  const hasTargetLinkUri = diff.targetLinkUri !== null
  const hasOidcInitiationUrl = diff.oidcInitiationUrl !== null
  const hasOidcInitiationUrls = diff.oidcInitiationUrls !== null
  const hasPublicJwk = diff.publicJwk !== null
  const hasPublicJwkUrl = diff.publicJwkUrl !== null
  const hasDomain = diff.domain !== null
  const hasCustomFields = diff.customFields !== null

  const hasAnyChanges =
    hasRedirectUriChanges ||
    hasTargetLinkUri ||
    hasOidcInitiationUrl ||
    hasOidcInitiationUrls ||
    hasPublicJwk ||
    hasPublicJwkUrl ||
    hasDomain ||
    hasCustomFields

  if (!hasAnyChanges) {
    return null
  }

  return (
    <View as="div" margin="large 0">
      <Heading level="h3" margin="0 0 small 0">
        {I18n.t('Launch Settings')}
      </Heading>

      <DiffList
        label={I18n.t('Redirect URIs')}
        additions={diff.redirectUris?.added}
        removals={diff.redirectUris?.removed}
      />

      <Diff label={I18n.t('Target Link URI')} diff={diff.targetLinkUri} />

      <Diff label={I18n.t('OIDC Initiation URL')} diff={diff.oidcInitiationUrl} />

      <DiffRecord
        label={I18n.t('OIDC Initiation URLs')}
        additions={diff.oidcInitiationUrls?.added}
        removals={diff.oidcInitiationUrls?.removed}
      />

      <View as="div" margin="small 0">
        <Diff
          label={I18n.t('Public JWK')}
          diff={diff.publicJwk}
          formatter={j => (j ? JSON.stringify(j, null, 2) : '')}
        />
      </View>

      <Diff label={I18n.t('Public JWK URL')} diff={diff.publicJwkUrl} />

      <Diff label={I18n.t('Domain')} diff={diff.domain} />

      <DiffRecord
        label={I18n.t('Custom Fields')}
        additions={diff.customFields?.added}
        removals={diff.customFields?.removed}
      />
    </View>
  )
}
