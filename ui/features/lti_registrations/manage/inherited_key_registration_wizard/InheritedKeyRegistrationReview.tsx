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
import * as React from 'react'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {htmlEscape} from '@instructure/html-escape'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {formatApiResultError, type ApiResult} from '../../common/lib/apiResult/ApiResult'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'
import {i18nLtiPrivacyLevelDescription} from '../model/i18nLtiPrivacyLevel'
import {
  LtiPlacementsWithIcons,
  type LtiPlacement,
  type LtiPlacementWithIcon,
} from '../model/LtiPlacement'
import {LaunchSettingsHeader, ReviewSection} from '../registration_wizard_forms/ReviewScreen'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'

export type InheritedKeyRegistrationReviewProps = {
  result: ApiResult<LtiRegistrationWithConfiguration>
}

const I18n = createI18nScope('lti_registration.wizard')

export const InheritedKeyRegistrationReview = (props: InheritedKeyRegistrationReviewProps) => {
  const [expandCustomFields, setExpandCustomFields] = React.useState(false)

  if (props.result._type === 'Success' && props.result.data.configuration) {
    const toolConfiguration = props.result.data.configuration
    const placements = toolConfiguration.placements ?? []

    const labels =
      placements.reduce(
        (acc, p) => {
          acc[p.placement] = p.text !== null ? p.text : undefined
          return acc
        },
        {} as Partial<Record<LtiPlacement, string>>,
      ) ?? {}

    const iconUrls =
      placements.reduce(
        (acc, p) => {
          if (p.icon_url) {
            acc[p.placement] = p.icon_url
          }
          return acc
        },
        {} as Partial<Record<LtiPlacement, string>>,
      ) ?? {}

    const customFields = toolConfiguration.custom_fields ?? {}

    const customFieldStrings = Object.keys(customFields).reduce((acc, key) => {
      return acc.concat(`${key}=${customFields[key]}`)
    }, [] as string[])

    return (
      <>
        <Alert variant="info" margin="0 0 medium 0">
          {I18n.t(
            "This app's configuration is managed by Instructure, so you cannot make changes.",
          )}
        </Alert>
        <View margin="medium 0 medium 0">
          <Heading level="h3">{I18n.t('Review')}</Heading>
          <Text>
            {I18n.t('The settings displayed are the configurations currently in use for this app.')}
          </Text>
        </View>
        <ReviewSection>
          <View>
            <Heading level="h4">{I18n.t('Launch Settings')}</Heading>
            <LaunchSettingsHeader>{I18n.t('Custom Fields')}</LaunchSettingsHeader>
            {customFieldStrings && customFieldStrings.length > 0 ? (
              <List
                margin="small 0 0 0"
                isUnstyled={true}
                delimiter="none"
                itemSpacing="small"
                size="small"
              >
                {customFieldStrings
                  .slice(0, expandCustomFields ? customFieldStrings.length : 3)
                  .map(field => (
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
            {customFieldStrings && customFieldStrings.length > 3 && (
              <Link onClick={() => setExpandCustomFields(!expandCustomFields)} margin="small 0 0 0">
                {expandCustomFields ? I18n.t('Show less') : I18n.t('Show more')}
              </Link>
            )}
          </View>
        </ReviewSection>
        <ReviewSection>
          <View>
            <Heading level="h4">{I18n.t('Data Sharing')}</Heading>
            <View margin="small 0 0 0">
              <Text size="small">
                {i18nLtiPrivacyLevelDescription(toolConfiguration.privacy_level || 'public')}
              </Text>
            </View>
          </View>
        </ReviewSection>
        <ReviewSection>
          <View>
            <Heading level="h4">{I18n.t('Placements')}</Heading>
            <Flex direction="column" gap="x-small" margin="small 0 0 0">
              {placements.map(placement => (
                <Text key={placement.placement} size="small">
                  {i18nLtiPlacement(placement.placement)}
                </Text>
              ))}
            </Flex>
          </View>
        </ReviewSection>
        <ReviewSection>
          <View>
            <Heading level="h4">{I18n.t('Naming')}</Heading>
            <Flex direction="column" gap="x-small" margin="small 0 0 0">
              <div>
                <Text size="small" weight="bold">
                  {I18n.t('Description')}:{' '}
                </Text>
                <Text
                  size="small"
                  dangerouslySetInnerHTML={{
                    __html: toolConfiguration.description
                      ? htmlEscape(toolConfiguration.description)
                      : I18n.t('*No description provided.*', {wrappers: ['<i>$1</i>']}),
                  }}
                />
              </div>
              {placements.map(p => {
                return (
                  <div key={p.placement}>
                    <Text size="small" weight="bold">
                      {i18nLtiPlacement(p.placement)}:{' '}
                    </Text>
                    <Text
                      size="small"
                      dangerouslySetInnerHTML={{
                        __html: labels[p.placement]
                          ? htmlEscape(labels[p.placement])
                          : I18n.t('**No label provided.**', {wrappers: ['<i>$1</i>']}),
                      }}
                    />
                  </div>
                )
              })}
            </Flex>
          </View>
        </ReviewSection>
        <ReviewSection>
          <View>
            <Heading level="h4">{I18n.t('Icon URLs')}</Heading>
            <Flex direction="column" gap="x-small" margin="small 0 0 0">
              {placements
                .map(p => p.placement)
                .filter((p): p is LtiPlacementWithIcon =>
                  LtiPlacementsWithIcons.includes(p as LtiPlacementWithIcon),
                )
                .map(p => {
                  let status: string
                  const url = iconUrls[p]

                  if (url) {
                    status = I18n.t('Custom Icon')
                  } else if (!url && p === 'editor_button') {
                    status = I18n.t('Generated Icon')
                  } else {
                    status = I18n.t('No Icon')
                  }

                  return (
                    <div key={p}>
                      <Text size="small" weight="bold">
                        {i18nLtiPlacement(p)}:{' '}
                      </Text>
                      <Text size="small">{status}</Text>
                    </div>
                  )
                })}
            </Flex>
          </View>
        </ReviewSection>
      </>
    )
  } else {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Dynamic Registration error')}
        errorCategory="Dynamic Registration"
        errorMessage={
          props.result._type === 'Success'
            ? 'No configuration present in the registration'
            : formatApiResultError(props.result)
        }
      />
    )
  }
}
