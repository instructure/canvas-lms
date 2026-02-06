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

import * as React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {SubSection} from './Section'

const I18n = createI18nScope('lti_registrations')

export type LaunchSettingsReadOnlyViewProps = {
  redirectUris?: string[]
  targetLinkUri?: string | null
  oidcInitiationUrl?: string | null
  publicJwkUrl?: string | null
  publicJwk?: unknown
  domain?: string | null
  customFields?: Record<string, string> | null
}

export const LaunchSettingsReadOnlyView = ({
  redirectUris,
  targetLinkUri,
  oidcInitiationUrl,
  publicJwkUrl,
  publicJwk,
  domain,
  customFields,
}: LaunchSettingsReadOnlyViewProps) => {
  const customFieldsEntries = Object.entries(customFields ?? {})

  return (
    <>
      {redirectUris && redirectUris.length > 0 && (
        <SubSection title={I18n.t('Redirect URIs:')}>
          {redirectUris.map((uri, i) => (
            <View display="block" key={i}>
              <Text>{uri}</Text>
            </View>
          ))}
        </SubSection>
      )}

      {targetLinkUri && (
        <SubSection title={I18n.t('Default Target Link URI:')}>
          <Text>{targetLinkUri}</Text>
        </SubSection>
      )}

      {oidcInitiationUrl && (
        <SubSection title={I18n.t('Open ID Connect Initiation URI:')}>
          {oidcInitiationUrl}
        </SubSection>
      )}

      {publicJwkUrl || publicJwk ? (
        <>
          <Flex direction="row" alignItems="end" margin="small 0 0">
            <Flex.Item margin="0 xx-small 0 0">
              <Text weight="bold">{I18n.t('JWK Method:')}</Text>
            </Flex.Item>

            <Flex.Item>
              {publicJwkUrl ? (
                <Text>{I18n.t('Public JWK URL')}</Text>
              ) : (
                <Text>{I18n.t('Public JWK')}</Text>
              )}
            </Flex.Item>
          </Flex>

          {publicJwkUrl ? (
            <SubSection title={I18n.t('Public JWK URL:')}>
              <Text>{publicJwkUrl}</Text>
            </SubSection>
          ) : publicJwk ? (
            <SubSection title={I18n.t('Public JWK:')}>
              <View as="div" margin="x-small 0 0 0">
                <pre style={{fontFamily: 'monospace'}}>{JSON.stringify(publicJwk, null, 2)}</pre>
              </View>
            </SubSection>
          ) : null}
        </>
      ) : null}

      <SubSection title={I18n.t('Domain:')}>
        {domain ? (
          <Text>{domain}</Text>
        ) : (
          <Text fontStyle="italic">{I18n.t('No domain configured.')}</Text>
        )}
      </SubSection>

      <SubSection title={I18n.t('Custom Fields:')}>
        {customFieldsEntries.length === 0 ? (
          <Text fontStyle="italic">{I18n.t('No custom fields configured.')}</Text>
        ) : (
          <View as="div" margin="x-small 0 0 0">
            <pre style={{fontFamily: 'monospace'}}>
              {customFieldsEntries.map(([key, field]) => `${key}=${field}`).join('\n')}
            </pre>
          </View>
        )}
      </SubSection>
    </>
  )
}
