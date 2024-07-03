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
import {i18nLtiScope} from '../../model/LtiScope'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import type {RegistrationOverlayStore} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import htmlEscape from '@instructure/html-escape'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('lti_registration.wizard')

export type PermissionConfirmationProps = {
  registration: LtiImsRegistration
  overlayStore: RegistrationOverlayStore
}

export const PermissionConfirmation = ({
  registration,
  overlayStore,
}: PermissionConfirmationProps) => {
  const [{state, ...actions}, setState] = React.useState(overlayStore.getState())
  React.useEffect(
    () =>
      overlayStore.subscribe(s => {
        setState(s)
      }),
    [overlayStore]
  )

  return (
    <>
      <Heading level="h3" margin="0 0 x-small 0">
        {I18n.t('Permissions')}
      </Heading>
      {registration.scopes.length === 0 ? (
        <Text
          dangerouslySetInnerHTML={{
            __html: I18n.t("*%{toolName}* hasn't requested any permissions.", {
              wrapper: '<strong>$1</strong>',
              toolName: htmlEscape(registration.client_name),
            }),
          }}
        />
      ) : (
        <>
          <Text
            dangerouslySetInnerHTML={{
              __html: I18n.t(
                "*%{toolName}* is requesting permission to perform the following actions. We have chosen the app's recommended default settings. Please note that altering these defaults might impact the app's performance.",
                {toolName: htmlEscape(registration.client_name), wrapper: '<strong>$1</strong>'}
              ),
            }}
          />
          <Flex direction="column" alignItems="center" gap="small" margin="medium 0 medium 0">
            {registration.scopes.map(scope => {
              return (
                <Checkbox
                  data-testid={scope}
                  key={scope}
                  variant="toggle"
                  label={i18nLtiScope(scope)}
                  checked={!state.registration.disabledScopes?.includes(scope)}
                  onChange={() => {
                    actions.toggleDisabledScope(scope)
                  }}
                />
              )
            })}
          </Flex>
        </>
      )}
    </>
  )
}
