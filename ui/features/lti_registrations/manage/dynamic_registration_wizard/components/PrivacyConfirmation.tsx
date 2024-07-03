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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import type {RegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import {htmlEscape} from '@instructure/html-escape'
import {
  AllLtiPrivacyLevels,
  i18nLtiPrivacyLevel,
  i18nLtiPrivacyLevelDescription,
  isLtiPrivacyLevel,
} from '../../model/LtiPrivacyLevel'
import {Flex} from '@instructure/ui-flex'

export type PrivacyConfirmationProps = {
  toolName: string
  overlayStore: RegistrationOverlayStore
}

const I18n = useI18nScope('lti_registration.wizard')

export const PrivacyConfirmation = ({toolName, overlayStore}: PrivacyConfirmationProps) => {
  const [{state, ...actions}, setState] = React.useState(overlayStore.getState())
  React.useEffect(
    () =>
      overlayStore.subscribe(s => {
        setState(s)
      }),
    [overlayStore]
  )

  const selectedPrivacyLevel = state.registration.privacy_level
  const messages = isLtiPrivacyLevel(selectedPrivacyLevel)
    ? [
        {
          text: (
            <Text size="small" weight="light">
              {i18nLtiPrivacyLevelDescription(selectedPrivacyLevel)}
            </Text>
          ),
          type: 'hint' as const,
        },
      ]
    : []

  return (
    <>
      <Heading level="h3" margin="0 0 x-small 0">
        {I18n.t('Data Sharing')}
      </Heading>
      <Text
        dangerouslySetInnerHTML={{
          __html: I18n.t('Select what data *%{toolName}* has access to.', {
            toolName: htmlEscape(toolName),
            wrapper: ['<strong>$1</strong>'],
          }),
        }}
      />
      <View margin="medium 0 medium 0" as="div">
        <SimpleSelect
          messages={messages}
          renderLabel={I18n.t('User Data Shared With This App')}
          value={selectedPrivacyLevel}
          onChange={(_, {value}) => {
            if (isLtiPrivacyLevel(value)) {
              actions.updatePrivacyLevel(value)
            }
          }}
        >
          {AllLtiPrivacyLevels.map(level => (
            <SimpleSelect.Option key={level} value={level} id={level}>
              {i18nLtiPrivacyLevel(level)}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </View>
    </>
  )
}
