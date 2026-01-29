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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAddSolid, IconCheckSolid, IconNeutralSolid, IconNoSolid} from '@instructure/ui-icons'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import React from 'react'
import type {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import type {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {Alert} from '@instructure/ui-alerts'
import {ChangeInfo, summarizeRegistrationUpdateChanges} from './summarizeRegistrationUpdateChanges'

const I18n = createI18nScope('lti_registrations')

export interface RegistrationUpdateReviewProps {
  registrationUpdateRequest: LtiRegistrationUpdateRequest
  registration: LtiRegistrationWithConfiguration
}

export const RegistrationUpdateReview = ({
  registrationUpdateRequest,
  registration,
}: RegistrationUpdateReviewProps) => {
  const changes = summarizeRegistrationUpdateChanges(registrationUpdateRequest, registration)

  const renderChangeSection = (title: string, items: ChangeInfo[], icon: React.ReactElement) => {
    if (items.length === 0) return null

    return (
      <View as="div" margin="0" borderWidth="small" borderRadius="large" padding="small">
        <ToggleDetails
          summary={
            <Flex alignItems="center" gap="small">
              <Flex.Item>{icon}</Flex.Item>
              <Flex.Item>{title}</Flex.Item>
            </Flex>
          }
          iconPosition="end"
          defaultExpanded={true}
          fluidWidth
        >
          <List margin="0 0 0 x-small" isUnstyled>
            {items.map((item, index) => (
              <List.Item key={index} margin="small 0 0 0">
                <Text>{item.section}</Text>
                {item.detail && (
                  <View margin="xx-small 0 0 xx-small" as="div">
                    <Text fontStyle="italic">{item.detail}</Text>
                  </View>
                )}
              </List.Item>
            ))}
          </List>
        </ToggleDetails>
      </View>
    )
  }

  return (
    <View as="div">
      <Heading level="h3" margin="0 0 medium 0">
        {I18n.t('Update Summary')}
      </Heading>

      {registrationUpdateRequest.comment && (
        <Alert variant="info" margin="0 0 medium 0" variantScreenReaderLabel={I18n.t('Info')}>
          <Text>{registrationUpdateRequest.comment}</Text>
        </Alert>
      )}

      <Flex direction="column" gap="small">
        {renderChangeSection(I18n.t('Removed'), changes.removed, <IconNeutralSolid />)}
        {renderChangeSection(I18n.t('Added or Updated'), changes.added, <IconAddSolid />)}
        {renderChangeSection(I18n.t('No Changes'), changes.noChange, <IconCheckSolid />)}
      </Flex>

      {changes.added.length === 0 && changes.removed.length === 0 && (
        <View as="div" margin="large 0">
          <Text weight="bold">
            {I18n.t('No changes detected. The registration will remain the same.')}
          </Text>
        </View>
      )}
    </View>
  )
}
