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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React from 'react'
import htmlEscape from '@instructure/html-escape'
import type {RegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import {useOverlayStore} from '../hooks/useOverlayStore'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {usePlacements} from '../hooks/usePlacements'
import {i18nLtiPlacement} from '../../model/LtiPlacement'

const I18n = useI18nScope('lti_registration.wizard')

export type NamingConfirmationProps = {
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
}

export const NamingConfirmation = ({registration, overlayStore}: NamingConfirmationProps) => {
  const [overlayState, actions] = useOverlayStore(overlayStore)
  const placements = usePlacements(registration)

  return (
    <Flex direction="column">
      <>
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Nickname')}
        </Heading>
        <Text
          dangerouslySetInnerHTML={{
            __html: I18n.t('Choose a nickname for *%{toolName}*.', {
              toolName: htmlEscape(registration.client_name),
              wrapper: ['<strong>$1</strong>'],
            }),
          }}
        />
        <View margin="medium 0 0 0" as="div">
          <TextInput
            renderLabel={I18n.t('Administration Nickname')}
            value={overlayState.adminNickname ?? registration.client_name}
            onChange={(_, value) => actions.updateAdminNickname(value)}
          />
          <Text size="small">
            {I18n.t("The nickname will always appear next to the App's name")}
          </Text>
        </View>
      </>
      <View margin="medium 0 medium 0" as="div">
        <Heading level="h3" margin="0 0 x-small 0">
          {I18n.t('Description')}
        </Heading>
        <TextArea
          label={
            <Text weight="normal">
              {I18n.t(
                'Choose a description for this tool to display in the Link Selection and Assignment Selection placements for all accounts.'
              )}
            </Text>
          }
          value={
            overlayState.registration.description ??
            registration.default_configuration.description ??
            ''
          }
          onChange={e => {
            actions.updateDescription(e.target.value)
          }}
        />
      </View>
      {placements.length > 0 && (
        <>
          <Heading level="h3" margin="0 0 x-small 0">
            {I18n.t('Placement Names')}
          </Heading>
          <Text>{I18n.t('Choose a name override for each placement (optional).')}</Text>
          <Flex direction="column" gap="medium" margin="medium 0 medium 0">
            {placements.map(placement => {
              const overlayPlacement = overlayState.registration.placements?.find(
                p => p.type === placement
              )
              return (
                <TextInput
                  key={placement}
                  renderLabel={i18nLtiPlacement(placement)}
                  value={overlayPlacement?.label ?? ''}
                  onChange={(_, value) =>
                    actions.updatePlacement(placement)(p => ({...p, label: value}))
                  }
                />
              )
            })}
          </Flex>
        </>
      )}
    </Flex>
  )
}
