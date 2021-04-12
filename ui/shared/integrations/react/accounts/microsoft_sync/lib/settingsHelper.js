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

import I18n from 'i18n!account_settings_jsx_bundle'
import doFetchApi from '@canvas/do-fetch-api-effect'

/**
 * Using the provided parameters, updates the Microsoft Teams Sync settings for the current
 * account.
 *
 * @param {boolean} syncEnabled Whether MSFT Teams Sync should be enabled or not.
 * @param {string} syncTenant The tenant to use
 * @param {string} syncLoginAttr The login attribute to use
 */
export async function doUpdateSettings(syncEnabled, syncTenant, syncLoginAttr) {
  await doFetchApi({
    path: `/api/v1/${ENV.CONTEXT_BASE_URL}`,
    method: 'PUT',
    body: {
      account: {
        settings: {
          microsoft_sync_enabled: syncEnabled,
          microsoft_sync_tenant: syncTenant,
          microsoft_sync_login_attribute: syncLoginAttr
        }
      }
    }
  })
}
/**
 * Using the provided state from the reducer function, checks if the tenant is valid and adds error messages
 * as appropriate.
 * @param {import('./settingsReducer').State} state The state containing the tenant to be validated
 * @returns {import('./settingsReducer').State} The modified state, with an error message if the tenant is invalid
 */
export function validateTenant(state) {
  const regex = /^(?:[\w-]+\.[\w-]+)+$/
  if (!state.microsoft_sync_tenant) {
    state.tenantErrorMessages = [
      {
        text: I18n.t('To toggle Microsoft Teams Sync you need to input a tenant domain.'),
        type: 'error'
      }
    ]
  } else if (!regex.test(state.microsoft_sync_tenant)) {
    state.tenantErrorMessages = [
      {
        text: I18n.t(
          'Please provide a valid tenant domain. Check your Azure Active Directory settings to find it.'
        ),
        type: 'error'
      }
    ]
  } else {
    state.tenantErrorMessages = []
  }
  return state
}
