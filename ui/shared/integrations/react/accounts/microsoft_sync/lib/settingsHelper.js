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

import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {pick} from 'lodash'

const I18n = useI18nScope('account_settings_jsx_bundle')

export const SYNC_SETTINGS = [
  'microsoft_sync_enabled',
  'microsoft_sync_tenant',
  'microsoft_sync_login_attribute',
  'microsoft_sync_login_attribute_suffix',
  'microsoft_sync_remote_attribute',
]

/**
 * Using the provided parameters, updates the Microsoft Teams Sync settings for the current
 * account.
 *
 * @param {import('./settingsReducer').State} state The state whose values to use to update settings.
 */
export async function doUpdateSettings(state) {
  await doFetchApi({
    path: `/api/v1/${ENV.CONTEXT_BASE_URL}`,
    method: 'PUT',
    body: {
      account: {
        settings: sliceSyncSettings(state),
      },
    },
  })
}

/**
 *
 * @param {Object} obj
 * @returns Returns the properties from obj that match actual Microsoft
 * Sync settings used by the API.
 */
export function sliceSyncSettings(obj) {
  const syncSettings = pick(obj, SYNC_SETTINGS)
  if (syncSettings.microsoft_sync_login_attribute_suffix) {
    syncSettings.microsoft_sync_login_attribute_suffix =
      syncSettings.microsoft_sync_login_attribute_suffix.trim()
  }
  return syncSettings
}

/**
 * Using the provided state from the reducer function, checks if the tenant is valid and
 * returns an array of appropriate error messages.
 * @param {import('./settingsReducer').State} state The state containing the tenant to be validated
 * @returns {[{text: string, type: string}]} An array of error messages. Returns an empty array
 * if no errors were found.
 */
export function getTenantErrorMessages(state) {
  const regex = /^(?:[\w-]+\.[\w-]+)+$/
  if (!state.microsoft_sync_tenant) {
    return [
      {
        text: I18n.t('To toggle Microsoft Teams Sync you need to input a tenant domain.'),
        type: 'error',
      },
    ]
  } else if (!regex.test(state.microsoft_sync_tenant)) {
    return [
      {
        text: I18n.t(
          'Please provide a valid tenant domain. Check your Azure Active Directory settings to find it.'
        ),
        type: 'error',
      },
    ]
  }
  return []
}

/**
 * Returns an array of error messages related to the suffix of the specified state.
 * @param {import('./settingsReducer').State} state
 * @returns {[{text: string, type: string}]} An array of error messages related to the suffix
 * on the specified state. If no errors are found, returns an empty array.
 */
export function getSuffixErrorMessages(state) {
  const regex = /\s/
  if (state.microsoft_sync_login_attribute_suffix.length > 255) {
    return [
      {
        text: I18n.t(
          'A suffix cannot be longer than 255 characters. Please use a shorter suffix and try again.'
        ),
        type: 'error',
      },
    ]
  } else if (regex.test(state.microsoft_sync_login_attribute_suffix.trim())) {
    return [
      {
        text: I18n.t('A suffix cannot have any tabs or spaces. Please remove them and try again.'),
        type: 'error',
      },
    ]
  } else {
    return []
  }
}

/**
 * Sets the hint message that is shown when changing
 * the tenant.
 *
 * @param {import('./settingsReducer').State} state The state containing the tenant to be validated
 * @param payload The data given to the reducer, which contains the new tenant input text
 * @returns {{text: string, type: string}[]} The array of tenantInfoMessages
 */
export function setTenantInfoMessages(state, payload) {
  let tenantInfoMessages = []

  if (payload.microsoft_sync_tenant !== state.last_saved_microsoft_sync_tenant) {
    tenantInfoMessages = [
      {
        text: I18n.t('Changing the tenant will delete existing groups.'),
        type: 'hint',
      },
    ]
  }

  return tenantInfoMessages
}
