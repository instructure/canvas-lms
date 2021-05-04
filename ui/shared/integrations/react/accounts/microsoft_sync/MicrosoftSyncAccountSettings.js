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
import I18n from 'i18n!account_settings_jsx_bundle'
import React from 'react'
import LoginAttributeSelector from './components/LoginAttributeSelector'
import MicrosoftSyncTitle from './components/MicrosoftSyncTitle'
import TenantInput from './components/TenantInput'
import UpdateSettingsButton from './components/UpdateSettingsButton'
import AdminConsentLink from './components/AdminConsentLink'
import {reducerActions} from './lib/settingsReducer'
import useSettings from './lib/useSettings'

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
              renderCloseButtonLabel="Close"
              margin="small"
              onDismiss={() => dispatch({type: reducerActions.removeAlerts})}
            >
              {state.errorMessage}
            </Alert>
          )}
          {state.successMessage && (
            <Alert
              variant="success"
              renderCloseButtonLabel="Close"
              margin="small"
              onDismiss={() => dispatch({type: reducerActions.removeAlerts})}
            >
              {state.successMessage}
            </Alert>
          )}
        </div>
        <MicrosoftSyncTitle
          handleClick={() => {
            dispatch({type: reducerActions.toggleSync, dispatch})
          }}
          isEnabled={state.microsoft_sync_enabled}
        />
        <TenantInput
          tenantInputHandler={event =>
            dispatch({
              type: reducerActions.updateTenant,
              payload: {microsoft_sync_tenant: event.target.value}
            })
          }
          messages={state.tenantErrorMessages}
          tenant={state.microsoft_sync_tenant}
        />
        <LoginAttributeSelector
          attributeChangedHandler={(event, {value}) =>
            dispatch({
              type: reducerActions.updateAttribute,
              payload: {microsoft_sync_login_attribute: event.target.id, selectedAttribute: value}
            })
          }
          selectedLoginAttribute={state.selectedAttribute}
        />
        <UpdateSettingsButton
          handleClick={() => {
            dispatch({type: reducerActions.updateSettings, dispatch})
          }}
        />
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
