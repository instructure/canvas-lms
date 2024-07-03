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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine} from '@instructure/ui-icons'
import {List} from '@instructure/ui-list'
import {i18nLtiScope} from '../../model/LtiScope'
import {i18nLtiPrivacyLevelDescription} from '../../model/LtiPrivacyLevel'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {
  canvasPlatformSettings,
  type RegistrationOverlayStore,
} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {type ConfirmationStateType} from '../DynamicRegistrationWizardState'
import {
  i18nLtiPlacement,
  LtiPlacementsWithIcons,
  type LtiPlacementWithIcon,
} from '../../model/LtiPlacement'
import {htmlEscape} from '@instructure/html-escape'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'

const I18n = useI18nScope('lti_registration.wizard')

export type ReviewScreenProps = {
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
  transitionToConfirmationState: (from: ConfirmationStateType, to: ConfirmationStateType) => void
}

export const ReviewScreen = ({
  registration,
  overlayStore,
  transitionToConfirmationState,
}: ReviewScreenProps) => {
  const [overlayState] = useOverlayStore(overlayStore)

  return (
    <>
      <View margin="medium 0 medium 0">
        <Heading level="h3">{I18n.t('Review')}</Heading>
        <Text>{I18n.t('Review your changes before finalizing.')}</Text>
      </View>
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
            {registration.scopes
              .filter(s => !overlayState.registration.disabledScopes?.includes(s))
              .map(scope => (
                <List.Item key={scope}>
                  <Text size="small">{i18nLtiScope(scope)}</Text>
                </List.Item>
              ))}
          </List>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Permissions')}
          onClick={() => transitionToConfirmationState('Reviewing', 'PermissionConfirmation')}
        />
      </ReviewSection>
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Data Sharing')}</Heading>
          <View margin="small 0 0 0">
            <Text size="small">
              {i18nLtiPrivacyLevelDescription(
                overlayState.registration.privacy_level ??
                  canvasPlatformSettings(registration.tool_configuration)?.privacy_level ??
                  'anonymous'
              )}
            </Text>
          </View>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Data Sharing')}
          onClick={() => transitionToConfirmationState('Reviewing', 'PrivacyLevelConfirmation')}
        />
      </ReviewSection>
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Placements')}</Heading>
          <Flex direction="column" gap="x-small" margin="small 0 0 0">
            {canvasPlatformSettings(registration.tool_configuration)
              ?.settings.placements.filter(
                p => !overlayState.registration.disabledPlacements?.includes(p.placement)
              )
              .map(placement => (
                <Text key={placement.placement} size="small">
                  {i18nLtiPlacement(placement.placement)}
                </Text>
              ))}
          </Flex>
        </View>
        <IconButton
          renderIcon={IconEditLine}
          screenReaderLabel={I18n.t('Edit Placements')}
          onClick={() => transitionToConfirmationState('Reviewing', 'PlacementsConfirmation')}
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
              <Text size="small">
                {overlayState.adminNickname ?? registration.client_name ?? ''}
              </Text>
            </div>
            <div>
              <Text size="small" weight="bold">
                {I18n.t('Description')}:{' '}
              </Text>
              <Text
                size="small"
                dangerouslySetInnerHTML={{
                  __html: overlayState.registration.description
                    ? htmlEscape(overlayState.registration.description)
                    : I18n.t('*No description provided.*', {wrappers: ['<i>$1</i>']}),
                }}
              />
            </div>
            {overlayState.registration.placements?.map(p => {
              return (
                <div key={p.type}>
                  <Text size="small" weight="bold">
                    {i18nLtiPlacement(p.type)}:{' '}
                  </Text>
                  <Text
                    size="small"
                    dangerouslySetInnerHTML={{
                      __html: p.label
                        ? htmlEscape(p.label)
                        : I18n.t('**No label provided.**', {wrappers: ['<i>$1</i>']}),
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
          onClick={() => transitionToConfirmationState('Reviewing', 'NamingConfirmation')}
        />
      </ReviewSection>
      <ReviewSection>
        <View>
          <Heading level="h4">{I18n.t('Icon URLs')}</Heading>
          <Flex direction="column" gap="x-small" margin="small 0 0 0">
            {overlayState.registration.placements
              ?.filter(p => LtiPlacementsWithIcons.includes(p.type as LtiPlacementWithIcon))
              .map(p => {
                const registrationPlacement = canvasPlatformSettings(
                  registration.tool_configuration
                )?.settings.placements.find(rp => rp.placement === p.type)
                let status: string
                const usingDefaultIcon = () =>
                  // The overlay icon matches the registration icon
                  (p.icon_url && p.icon_url === registrationPlacement?.icon_url) ||
                  // We don't have a placement specific overlay icon, but the placement does have an icon
                  (!p.icon_url && registrationPlacement?.icon_url) ||
                  // We don't have a placement specific icon anywhere, but we do have a top-level icon
                  (!p.icon_url &&
                    canvasPlatformSettings(registration.tool_configuration)?.settings.icon_url)

                if (usingDefaultIcon()) {
                  status = I18n.t('Default Icon')
                } else if (p.icon_url) {
                  status = I18n.t('Custom Icon')
                } else if (!p.icon_url && p.type === 'editor_button') {
                  status = I18n.t('Generated Icon')
                } else {
                  status = I18n.t('No Icon')
                }

                return (
                  <div key={p.type}>
                    <Text size="small" weight="bold">
                      {i18nLtiPlacement(p.type)}:{' '}
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
          onClick={() => transitionToConfirmationState('Reviewing', 'IconConfirmation')}
        />
      </ReviewSection>
    </>
  )
}

const ReviewSection = ({children}: React.PropsWithChildren<{}>) => {
  return (
    <Flex margin="medium 0 medium 0" alignItems="start" justifyItems="space-between">
      {children}
    </Flex>
  )
}
