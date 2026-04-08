/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAddSolid, IconNeutralSolid} from '@instructure/ui-icons'
import {compareSubstitutionVariables} from '../lib/extractSubstitutionVariables'
import {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('lti_registrations')

export type CustomVariablesListProps = {
  internalConfiguration?: InternalLtiConfiguration
  registrationUpdateRequest?: LtiRegistrationUpdateRequest
}

const VariableItem = ({variable}: {variable: string}) => (
  <List.Item padding="0">
    <Flex direction="column">
      <Flex.Item>
        <Link
          href={`/doc/api/file.tools_variable_substitutions.html#${variable.toLowerCase().replace('$', '').replace(/\./g, '-')}`}
          target="_blank"
        >
          {variable}
        </Link>
      </Flex.Item>
    </Flex>
  </List.Item>
)

/**
 * Displays a list of custom variable substitutions that have been configured
 * for an LTI tool registration.
 *
 */
export const CustomVariablesList = ({
  internalConfiguration,
  registrationUpdateRequest,
}: CustomVariablesListProps) => {
  if (!window.ENV.FEATURES?.substitution_variable_display) {
    return null
  }

  if (!internalConfiguration) {
    return null
  }

  const {unchanged, added, removed} = compareSubstitutionVariables(
    internalConfiguration,
    registrationUpdateRequest?.internal_lti_configuration,
  )

  if (unchanged.size === 0 && added.size === 0 && removed.size === 0) {
    return null
  }

  return (
    <View as="div" margin="medium 0">
      <View as="div" margin="0 0 x-small 0">
        <Heading level="h4" margin="0">
          {I18n.t('Extra Data')}
        </Heading>
        <Text>{I18n.t('This app will receive the following additional data in launches:')}</Text>
      </View>

      {unchanged.size > 0 && (
        <View as="div" margin="0 0 medium 0">
          <List margin="0">
            {Array.from(unchanged).map(variable => (
              <VariableItem key={variable} variable={variable} />
            ))}
          </List>
        </View>
      )}

      {added.size > 0 && (
        <View as="div" margin="small 0 medium 0">
          <Heading level="h4" margin="0 0 x-small 0">
            <Flex direction="row" gap="small">
              <IconAddSolid />
              {I18n.t('Added')}
            </Flex>
          </Heading>
          <List margin="0">
            {Array.from(added).map(variable => (
              <VariableItem key={variable} variable={variable} />
            ))}
          </List>
        </View>
      )}

      {removed.size > 0 && (
        <View as="div" margin="small 0 0 0">
          <Heading level="h4" margin="0 0 x-small 0">
            <Flex direction="row" gap="small">
              <IconNeutralSolid />
              {I18n.t('Removed')}
            </Flex>
          </Heading>
          <List margin="0">
            {Array.from(removed).map(variable => (
              <VariableItem key={variable} variable={variable} />
            ))}
          </List>
        </View>
      )}
    </View>
  )
}
