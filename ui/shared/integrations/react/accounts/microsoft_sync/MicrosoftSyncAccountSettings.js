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
import {Button} from '@instructure/ui-buttons'
import {IconUploadLine} from '@instructure/ui-icons'
import I18n from 'i18n!account_settings_jsx_bundle'
import React from 'react'
import LoginAttributeSelector from './components/LoginAttributeSelector'
import MicrosoftSyncTitle from './components/MicrosoftSyncTitle'
import TenantInput from './components/TenantInput'
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
        <Button
          renderIcon={IconUploadLine}
          interaction={state.uiEnabled ? 'enabled' : 'disabled'}
          color="primary"
          onClick={() => dispatch({type: reducerActions.updateSettings, dispatch})}
          margin="small 0 small 0"
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
