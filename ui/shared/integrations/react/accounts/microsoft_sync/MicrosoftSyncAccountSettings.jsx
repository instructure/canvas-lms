/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconInfoLine, IconUploadLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Table} from '@instructure/ui-table'
import LoginAttributeSelector from './components/LoginAttributeSelector'
import MicrosoftSyncTitle from './components/MicrosoftSyncTitle'
import TenantInput from './components/TenantInput'
import AdminConsentLink from './components/AdminConsentLink'
import {reducerActions} from './lib/settingsReducer'
import useSettings from './lib/useSettings'
import {Tooltip} from '@instructure/ui-tooltip'
import LoginAttributeSuffixInput from './components/LoginAttributeSuffixInput'
import ActiveDirectoryLookupAttributeSelector from './components/ActiveDirectoryLookupAttributeSelector'

const I18n = useI18nScope('account_settings_jsx_bundle')

export default function MicrosoftSyncAccountSettings() {
  const [state, dispatch] = useSettings()

  if (state.loading) {
    return (
      <Flex justifyItems="center">
        <Flex.Item>
          <Spinner
            renderTitle={I18n.t('Loading Microsoft Teams Sync settings')}
            size="medium"
            margin="0 0 0 medium"
          />
        </Flex.Item>
      </Flex>
    )
  } else {
    return (
      <View>
        <div role="region" aria-live="polite">
          {state.errorMessage && (
            <Alert
              variant="error"
              renderCloseButtonLabel={I18n.t('Close')}
              margin="small"
              onDismiss={() => dispatch({type: reducerActions.removeAlerts})}
              timeout={5000}
            >
              {state.errorMessage}
            </Alert>
          )}
          {state.successMessage && (
            <Alert
              variant="success"
              renderCloseButtonLabel={I18n.t('Close')}
              margin="small"
              onDismiss={() => dispatch({type: reducerActions.removeAlerts})}
              timeout={5000}
            >
              {state.successMessage}
            </Alert>
          )}
        </div>
        <MicrosoftSyncTitle
          handleClick={() => {
            dispatch({type: reducerActions.toggleSync, dispatch})
          }}
          syncEnabled={state.microsoft_sync_enabled}
          interactionDisabled={!state.uiEnabled}
        />

        <Table caption={I18n.t('Microsoft Teams Sync')}>
          <Table.Body>
            <Table.Row>
              <Table.RowHeader textAlign="start">
                <span>{I18n.t('Tenant Name')}</span>
                <Tooltip
                  renderTip={I18n.t('Your Azure Active Directory Tenant Name')}
                  on={['hover', 'focus']}
                >
                  <IconButton
                    screenReaderLabel="Tenant Name"
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                  />
                </Tooltip>
              </Table.RowHeader>

              <Table.Cell>
                <TenantInput
                  tenantInputHandler={event =>
                    dispatch({
                      type: reducerActions.updateTenant,
                      payload: {microsoft_sync_tenant: event.target.value},
                    })
                  }
                  messages={state.tenantErrorMessages.concat(state.tenantInfoMessages)}
                  tenant={state.microsoft_sync_tenant}
                />
              </Table.Cell>
            </Table.Row>

            <Table.Row>
              <Table.RowHeader textAlign="start">
                <span>{I18n.t('Login Attribute')}</span>
                <Tooltip
                  renderTip={I18n.t(
                    'The attribute to use when associating a Canvas User with a Microsoft User'
                  )}
                  placement="top"
                  on={['hover', 'focus']}
                >
                  <IconButton
                    screenReaderLabel="Login Attribute"
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                  />
                </Tooltip>
              </Table.RowHeader>

              <Table.Cell>
                <LoginAttributeSelector
                  attributeChangedHandler={(event, {value}) => {
                    dispatch({
                      type: reducerActions.updateAttribute,
                      payload: {microsoft_sync_login_attribute: value},
                    })
                  }}
                  selectedLoginAttribute={state.microsoft_sync_login_attribute}
                />
              </Table.Cell>
            </Table.Row>
            <Table.Row>
              <Table.RowHeader textAlign="start">
                <span>{I18n.t('Suffix')}</span>
                <Tooltip
                  renderTip={I18n.t(
                    'Not Required. If this is populated the entered text will be appended to the Login Attribute'
                  )}
                  on={['hover', 'focus']}
                >
                  <IconButton
                    screenReaderLabel="Suffix"
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                  />
                </Tooltip>
              </Table.RowHeader>
              <Table.Cell>
                <LoginAttributeSuffixInput
                  loginAttributeSuffix={state.microsoft_sync_login_attribute_suffix}
                  suffixInputHandler={event => {
                    dispatch({
                      type: reducerActions.updateSuffix,
                      payload: {microsoft_sync_login_attribute_suffix: event.target.value},
                    })
                  }}
                  messages={state.suffixErrorMessages}
                />
              </Table.Cell>
            </Table.Row>
            <Table.Row>
              <Table.RowHeader>
                <span>{I18n.t('Active Directory Lookup Attribute')}</span>
                <Tooltip
                  renderTip={I18n.t(
                    'The Active Directory attribute that will be used to match a Canvas user to a Microsoft user'
                  )}
                  on={['hover', 'focus']}
                >
                  <IconButton
                    screenReaderLabel="Active Directory Lookup Attribute"
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                  />
                </Tooltip>
              </Table.RowHeader>

              <Table.Cell>
                <ActiveDirectoryLookupAttributeSelector
                  fieldChangedHandler={(event, {value}) => {
                    dispatch({
                      type: reducerActions.updateRemoteAttribute,
                      payload: {microsoft_sync_remote_attribute: value},
                    })
                  }}
                  selectedLookupField={state.microsoft_sync_remote_attribute}
                />
              </Table.Cell>
            </Table.Row>
          </Table.Body>
        </Table>

        <Button
          renderIcon={IconUploadLine}
          interaction={state.uiEnabled ? 'enabled' : 'disabled'}
          color="primary"
          onClick={() => dispatch({type: reducerActions.updateSettings, dispatch})}
          margin="small 0 small 0"
          id="microsoft_teams_sync_update_button"
        >
          {I18n.t('Update Settings')}
        </Button>

        <AdminConsentLink
          enabled={
            state.microsoft_sync_enabled &&
            !!state.microsoft_sync_tenant &&
            state.tenantErrorMessages.length < 1
          }
          baseUrl={ENV.MICROSOFT_SYNC.BASE_URL}
          clientId={ENV.MICROSOFT_SYNC.CLIENT_ID}
          redirectUri={ENV.MICROSOFT_SYNC.REDIRECT_URI}
          tenant={state.microsoft_sync_tenant}
        />
      </View>
    )
  }
}
