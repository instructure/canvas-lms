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
import {useScope as createI18nScope} from '@canvas/i18n'
import {htmlEscape} from '@instructure/html-escape'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconEditLine} from '@instructure/ui-icons'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'
import {i18nLtiPrivacyLevelDescription} from '../model/i18nLtiPrivacyLevel'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {
  type LtiPlacement,
  LtiPlacementsWithIcons,
  type LtiPlacementWithIcon,
} from '../model/LtiPlacement'
import type {LtiScope} from '@canvas/lti/model/LtiScope'
import type {LtiPrivacyLevel} from '../model/LtiPrivacyLevel'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('lti_registration.wizard')

type LaunchSettings = {
  redirectUris?: string[]
  defaultTargetLinkUri?: string
  oidcInitiationUrl?: string
  jwkMethod: 'public_jwk' | 'public_jwk_url'
  jwk?: string
  jwkUrl?: string
  domain?: string
  customFields?: string[]
}

export type ReviewScreenProps = {
  scopes: LtiScope[]
  privacyLevel: LtiPrivacyLevel
  placements: LtiPlacement[]
  nickname?: string
  description?: string
  labels: Partial<Record<LtiPlacement, string>>
  iconUrls: Partial<Record<LtiPlacementWithIcon, string>>
  defaultPlacementIconUrls: Partial<Record<LtiPlacementWithIcon, string>>
  launchSettings?: LaunchSettings
  defaultIconUrl?: string
  onEditScopes: () => void
  onEditPrivacyLevel: () => void
  onEditPlacements: () => void
  onEditNaming: () => void
  onEditIconUrls: () => void
  onEditLaunchSettings?: () => void
}

export const ReviewScreen = ({
  launchSettings,
  scopes,
  privacyLevel,
  placements,
  nickname,
  description,
  labels,
  iconUrls,
  defaultIconUrl,
  defaultPlacementIconUrls = {},
  onEditScopes,
  onEditLaunchSettings,
  onEditPrivacyLevel,
  onEditPlacements,
  onEditNaming,
  onEditIconUrls,
}: ReviewScreenProps) => {
  return (
    <RegistrationModalBody>
      <View margin="medium 0 medium 0">
        <Heading level="h3">{I18n.t('Review')}</Heading>
        <Text>{I18n.t('Review your changes before finalizing.')}</Text>
      </View>
      {launchSettings && onEditLaunchSettings && (
        <LaunchSettingsSection {...launchSettings} onEditLaunchSettings={onEditLaunchSettings} />
      )}
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Permissions')}</Heading>
          <List
            margin="small 0 0 0"
            isUnstyled={true}
            delimiter="none"
            itemSpacing="small"
            size="small"
          >
            {scopes.length === 0 ? (
              <List.Item>
                <Text size="small" fontStyle="italic">
                  {I18n.t('No permissions requested')}
                </Text>
              </List.Item>
            ) : (
              scopes.map(scope => (
                <List.Item key={scope}>
                  <Text size="small">{i18nLtiScope(scope)}</Text>
                </List.Item>
              ))
            )}
          </List>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Permissions')}
          onClick={onEditScopes}
        />
      </ReviewSection>
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Data Sharing')}</Heading>
          <View margin="small 0 0 0">
            <Text size="small">{i18nLtiPrivacyLevelDescription(privacyLevel)}</Text>
          </View>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Data Sharing')}
          onClick={onEditPrivacyLevel}
        />
      </ReviewSection>
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Placements')}</Heading>
          <Flex direction="column" gap="x-small" margin="small 0 0 0">
            {placements.map(placement => (
              <Text key={placement} size="small">
                {i18nLtiPlacement(placement)}
              </Text>
            ))}
          </Flex>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Placements')}
          onClick={onEditPlacements}
        />
      </ReviewSection>
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Naming')}</Heading>
          <Flex direction="column" gap="x-small" margin="small 0 0 0">
            <div>
              <Text size="small" weight="bold">
                {I18n.t('Administration Nickname')}:{' '}
              </Text>
              <Text size="small" fontStyle={nickname ? 'normal' : 'italic'}>
                {nickname ?? I18n.t('No nickname provided.')}
              </Text>
            </div>
            <div>
              <Text size="small" weight="bold">
                {I18n.t('Description')}:{' '}
              </Text>
              <Text
                size="small"
                dangerouslySetInnerHTML={{
                  __html: description
                    ? htmlEscape(description)
                    : I18n.t('*No description provided.*', {wrappers: ['<i>$1</i>']}),
                }}
              />
            </div>
            {placements.map(placement => {
              return (
                <div key={placement}>
                  <Text size="small" weight="bold">
                    {i18nLtiPlacement(placement)}:{' '}
                  </Text>
                  <Text
                    size="small"
                    dangerouslySetInnerHTML={{
                      __html: labels[placement]
                        ? htmlEscape(labels[placement])
                        : I18n.t('*No label provided.*', {wrappers: ['<i>$1</i>']}),
                    }}
                  />
                </div>
              )
            })}
          </Flex>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Naming')}
          onClick={onEditNaming}
        />
      </ReviewSection>
      <IconUrlsReviewSection
        placements={placements}
        iconUrls={iconUrls}
        defaultPlacementIconUrls={defaultPlacementIconUrls}
        defaultIconUrl={defaultIconUrl}
        onEditIconUrls={onEditIconUrls}
      />
    </RegistrationModalBody>
  )
}

export const ReviewSection = ({children}: React.PropsWithChildren<{}>) => {
  return (
    <Flex margin="medium 0 medium 0" alignItems="start" justifyItems="space-between">
      {children}
    </Flex>
  )
}

export const LaunchSettingsHeader = ({children}: React.PropsWithChildren<{}>) => {
  return (
    <h5
      style={{
        fontSize: '14px',
        fontWeight: 'bold',
        margin: '0.75rem 0 0 0',
      }}
    >
      {children}
    </h5>
  )
}

export type LaunchSettingsSectionProps = LaunchSettings & {onEditLaunchSettings: () => void}

export const LaunchSettingsSection = React.memo(
  ({
    jwkMethod,
    onEditLaunchSettings,
    customFields,
    defaultTargetLinkUri,
    domain,
    jwk,
    jwkUrl,
    oidcInitiationUrl,
    redirectUris,
  }: LaunchSettingsSectionProps) => {
    const [expandCustomFields, setExpandCustomFields] = React.useState(false)
    const displayedJwk = React.useMemo(() => {
      if (jwk) {
        try {
          return JSON.stringify(JSON.parse(jwk), null, 2)
        } catch {
          return jwk
        }
      }
    }, [jwk])

    return (
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Launch Settings')}</Heading>
          <LaunchSettingsHeader>{I18n.t('Redirect URIs')}</LaunchSettingsHeader>
          {redirectUris ? (
            <List margin="0" isUnstyled={true} delimiter="none" itemSpacing="small" size="small">
              {redirectUris.map(uri => (
                <List.Item key={uri}>
                  <Text size="small">{uri}</Text>
                </List.Item>
              ))}
            </List>
          ) : (
            <Text size="small" fontStyle="italic">
              {I18n.t('No Redirect URIs Specified')}
            </Text>
          )}
          <LaunchSettingsHeader>{I18n.t('Default Target Link URI')}</LaunchSettingsHeader>
          <Text size="small">{defaultTargetLinkUri}</Text>
          <LaunchSettingsHeader>{I18n.t('OpenID Connect Initiation URL')}</LaunchSettingsHeader>
          <Text size="small">{oidcInitiationUrl}</Text>
          <LaunchSettingsHeader>{I18n.t('JWK Method')}</LaunchSettingsHeader>
          {jwkMethod === 'public_jwk_url' ? (
            <>
              <Text size="small">{I18n.t('Public JWK URL')}</Text>
              <LaunchSettingsHeader>{I18n.t('Public JWK URL')}</LaunchSettingsHeader>
              <Text size="small">{jwkUrl}</Text>
            </>
          ) : (
            <>
              <Text size="small">{I18n.t('Public JWK')}</Text>
              <LaunchSettingsHeader>{I18n.t('Public JWK')}</LaunchSettingsHeader>
              <p
                style={{
                  whiteSpace: 'pre-wrap',
                  fontFamily: 'monospace',
                  fontSize: '14px',
                  overflowWrap: 'anywhere',
                }}
              >
                {displayedJwk}
              </p>
            </>
          )}
          <LaunchSettingsHeader>{I18n.t('Domain')}</LaunchSettingsHeader>
          <Text size="small">{domain ?? I18n.t('No Domain Specified')}</Text>
          <LaunchSettingsHeader>{I18n.t('Custom Fields')}</LaunchSettingsHeader>
          {customFields && customFields.length > 0 ? (
            <List
              margin="small 0 0 0"
              isUnstyled={true}
              delimiter="none"
              itemSpacing="small"
              size="small"
            >
              {customFields.slice(0, expandCustomFields ? customFields.length : 3).map(field => (
                <List.Item key={field}>
                  <Text size="small">{field}</Text>
                </List.Item>
              ))}
            </List>
          ) : (
            <Text size="small" fontStyle="italic">
              {I18n.t('No Custom Fields Specified')}
            </Text>
          )}
          {customFields && customFields.length > 3 && (
            <Link onClick={() => setExpandCustomFields(!expandCustomFields)} margin="small 0 0 0">
              {expandCustomFields ? I18n.t('Show less') : I18n.t('Show more')}
            </Link>
          )}
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Launch Settings')}
          onClick={onEditLaunchSettings}
        />
      </ReviewSection>
    )
  },
)

export type IconUrlsReviewSectionProps = {
  placements: LtiPlacement[]
  iconUrls: ReviewScreenProps['iconUrls']
  defaultPlacementIconUrls: ReviewScreenProps['defaultPlacementIconUrls']
  defaultIconUrl?: string
  onEditIconUrls: () => void
}

export const IconUrlsReviewSection = React.memo(
  ({
    placements,
    iconUrls,
    defaultPlacementIconUrls,
    defaultIconUrl,
    onEditIconUrls,
  }: IconUrlsReviewSectionProps) => {
    const placementsWithIcons = placements.filter((p): p is LtiPlacementWithIcon =>
      LtiPlacementsWithIcons.includes(p as LtiPlacementWithIcon),
    )

    if (placementsWithIcons.length === 0) {
      return null
    }

    return (
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Icon URLs')}</Heading>
          <Flex direction="column" gap="x-small" margin="small 0 0 0">
            {placementsWithIcons.map(placement => {
              let status: string
              const iconUrl = iconUrls[placement]
              const defaultPlacementIconUrl = defaultPlacementIconUrls[placement]
              const usingDefaultIcon = // We're using the placement's default URL
                (!iconUrl && !!defaultPlacementIconUrl) ||
                // We're using the top-level default Icon URL
                (!iconUrl && !!defaultIconUrl) ||
                // Our configured URL matches the placement's default URL, and
                // both URL's are actually present
                (iconUrl === defaultPlacementIconUrl && !!iconUrl && !!defaultPlacementIconUrl) ||
                // Our configured URL matches the top-level default URL, and both
                // URL's are actually present
                (iconUrl === defaultIconUrl && !!iconUrl && !!defaultIconUrl)
              if (usingDefaultIcon) {
                status = I18n.t('Default Icon')
              } else if (iconUrl) {
                status = I18n.t('Custom Icon')
              } else if (!iconUrl && placement === 'editor_button') {
                status = I18n.t('Generated Icon')
              } else {
                status = I18n.t('No Icon')
              }

              return (
                <div key={placement}>
                  <Text size="small" weight="bold">
                    {i18nLtiPlacement(placement)}:{' '}
                  </Text>
                  <Text size="small">{status}</Text>
                </div>
              )
            })}
          </Flex>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Icon URLs')}
          onClick={onEditIconUrls}
        />
      </ReviewSection>
    )
  },
)
