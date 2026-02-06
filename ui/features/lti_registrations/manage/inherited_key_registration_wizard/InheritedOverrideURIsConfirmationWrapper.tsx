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
import {Heading} from '@instructure/ui-heading'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import type {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {ReadOnlyAlert} from './helpers'
import {View} from '@instructure/ui-view'
import {SubSection} from '../components/Section'
import {Text} from '@instructure/ui-text'
import type {LtiPlacement} from '../model/LtiPlacement'
import type {LtiMessageType} from '../model/LtiMessageType'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'

const I18n = createI18nScope('lti_registration.wizard')

export type InheritedOverrideURIsConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
}

export const InheritedOverrideURIsConfirmationWrapper = ({
  overlayStore,
}: InheritedOverrideURIsConfirmationWrapperProps) => {
  const overrideUris = overlayStore(s => s.state.override_uris.placements)

  return (
    <RegistrationModalBody>
      <Heading level="h3" margin="0 0 x-small 0">
        {I18n.t('Override URIs')}
      </Heading>

      <ReadOnlyAlert />

      {Object.keys(overrideUris).length === 0 ? (
        <Text fontStyle="italic">{I18n.t('No override URIs configured for this tool.')}</Text>
      ) : (
        Object.entries(overrideUris).map(([placement, config]) => (
          <View key={placement} as="div" margin="small 0">
            <SubSection title={`${i18nLtiPlacement(placement as LtiPlacement)}:`}>
              {config.message_type && (
                <View as="div" margin="x-small 0 0 medium">
                  <Text weight="bold">{I18n.t('Message Type: ')}</Text>
                  <Text>{config.message_type}</Text>
                </View>
              )}

              <View as="div" margin="x-small 0 0 medium">
                <Text weight="bold">{I18n.t('Override URI: ')}</Text>
                {config.uri ? (
                  <Text wrap="break-word">{config.uri}</Text>
                ) : (
                  <Text fontStyle="italic">{I18n.t('None')}</Text>
                )}
              </View>
            </SubSection>
          </View>
        ))
      )}
    </RegistrationModalBody>
  )
}
