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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import React from 'react'
import type {LtiScope} from '@canvas/lti/model/LtiScope'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'
import {IconAddSolid, IconNeutralSolid} from '@instructure/ui-icons'

const I18n = createI18nScope('lti_registration.wizard')

export type PermissionConfirmationProps = {
  /**
   * The name of the app that the user is configuring
   */
  appName: string
  /**
   * The list of scopes that are currently selected
   * by the user.
   */
  scopesSelected: LtiScope[]
  /**
   * The full list of scopes that should be
   * _possible_ to be selected
   * in the permission confirmation.
   */
  scopesSupported: readonly LtiScope[]
  /**
   * Called when a scope is toggled.
   * @param scope
   * @returns
   */
  onScopeToggled: (scope: LtiScope) => void
  /**
   * Whether or not to include the 'requesting' text
   * which state what permissions the app is "requesting"
   */
  showAllSettings?: boolean
  /**
   * Whether or not we are creating or editing a registration
   */
  mode: 'new' | 'edit'
  registrationUpdateRequest?: LtiRegistrationUpdateRequest
}

export const PermissionConfirmation = React.memo((props: PermissionConfirmationProps) => {
  return (
    <>
      <Heading level="h3" margin="0 0 x-small 0">
        {I18n.t('Permissions')}
      </Heading>
      {renderBody(props)}
    </>
  )
})

const renderBody = ({
  appName,
  scopesSupported,
  scopesSelected,
  onScopeToggled,
  showAllSettings,
  mode,
  registrationUpdateRequest,
}: PermissionConfirmationProps): React.ReactElement => {
  // registrationUpdateRequest?.internal_lti_configuration?.scopes ?? scopesSupported
  const updateRequestScopes = registrationUpdateRequest?.internal_lti_configuration?.scopes ?? []
  const newlyAddedScopes = registrationUpdateRequest
    ? updateRequestScopes.filter(scope => !scopesSupported.includes(scope))
    : []
  const removedScopes = registrationUpdateRequest
    ? scopesSupported.filter(scope => !updateRequestScopes.includes(scope))
    : []

  const empty = scopesSupported.length === 0 && updateRequestScopes.length === 0

  if (empty && mode === 'new') {
    return (
      <Text
        dangerouslySetInnerHTML={{
          __html: I18n.t("*%{toolName}* hasn't requested any permissions.", {
            wrapper: '<strong>$1</strong>',
            toolName: appName,
          }),
        }}
      />
    )
  } else if (empty && mode === 'edit') {
    return <Text fontStyle="italic">{I18n.t('This app has no permissions configured.')}</Text>
  } else {
    return (
      <>
        {mode === 'new' ? (
          <Text
            dangerouslySetInnerHTML={{
              __html: I18n.t(
                "*%{toolName}* is requesting permission to perform the following actions. We have chosen the app's recommended default settings. Please note that altering these defaults might impact the app's performance.",
                {toolName: appName, wrapper: '<strong>$1</strong>'},
              ),
            }}
          />
        ) : (
          <Text
            dangerouslySetInnerHTML={{
              __html: showAllSettings
                ? I18n.t(
                    'Select the permissions for *%{toolName}*. Services must be supported by the tool in order to work. Check with your app vendor to see what permissions are required.',
                    {toolName: appName, wrapper: '<strong>$1</strong>'},
                  )
                : I18n.t(
                    "Select the permissions for *%{toolName}*. Please note that altering these defaults might impact the app's performance.",
                    {
                      toolName: appName,
                      wrapper: '<strong>$1</strong>',
                    },
                  ),
            }}
          />
        )}

        <Flex direction="column" alignItems="center" gap="small" margin="medium 0 medium 0">
          {scopesSupported
            .filter(s => !removedScopes.includes(s))
            .map(scope => {
              return (
                <Checkbox
                  data-testid={scope}
                  key={scope}
                  variant="toggle"
                  label={i18nLtiScope(scope)}
                  checked={scopesSelected.includes(scope)}
                  onChange={() => {
                    onScopeToggled(scope)
                  }}
                />
              )
            })}
        </Flex>
        {newlyAddedScopes.length > 0 && (
          <Flex direction="column" alignItems="start" gap="small" margin="small 0 medium 0">
            <Heading level="h4" margin="0 0 x-small 0">
              <Flex direction="row" gap="small">
                <IconAddSolid />
                {I18n.t('Added')}
              </Flex>
            </Heading>
            {newlyAddedScopes.map(scope => (
              <Checkbox
                data-testid={scope}
                data-pendo="lti-permission-toggle"
                key={scope}
                variant="toggle"
                label={i18nLtiScope(scope)}
                checked={scopesSelected.includes(scope)}
                onChange={() => {
                  onScopeToggled(scope)
                }}
              />
            ))}
          </Flex>
        )}
        {removedScopes.length > 0 && (
          <Flex direction="column" alignItems="start" gap="small" margin="small 0 0 0">
            <Heading level="h4" margin="0 0 x-small 0">
              <Flex direction="row" gap="small">
                <IconNeutralSolid />
                {I18n.t('Removed')}
              </Flex>
            </Heading>
            {removedScopes.map(scope => (
              <Checkbox
                data-testid={scope}
                key={scope}
                disabled
                variant="toggle"
                label={i18nLtiScope(scope)}
                checked={false}
                onChange={() => {
                  onScopeToggled(scope)
                }}
              />
            ))}
          </Flex>
        )}
      </>
    )
  }
}
