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

import {
  doUpdateSettings,
  getTenantErrorMessages,
  setTenantInfoMessages,
  getSuffixErrorMessages,
} from './settingsHelper'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_settings_jsx_bundle')

/**
 * @typedef {Object} ReducerAction
 * @property {string} fetchSuccess
 * @property {string} fetchError
 * @property {string} fetchLoading
 * @property {string} updateSettings
 * @property {string} toggleSync
 * @property {string} updateTenant
 * @property {string} updateAttribute
 * @property {string} updateSuffix
 * @property {string} updateRemoteAttribute
 * @property {string} removeAlerts
 * @property {string} updateSuccess
 * @property {string} updateError
 * @property {string} toggleError
 */

/**
 * @type ReducerAction
 * A list of valid actions for the reducer.
 */
export const reducerActions = {
  fetchSuccess: 'fetchSuccess',
  fetchError: 'fetchError',
  fetchLoading: 'fetchLoading',
  updateSettings: 'updateSettings',
  toggleSync: 'toggleSync',
  updateSuffix: 'updateSuffix',
  updateRemoteAttribute: 'updateRemoteAttribute',
  updateTenant: 'updateTenant',
  updateAttribute: 'updateAttribute',
  removeAlerts: 'removeAlerts',
  updateSuccess: 'updateSuccess',
  updateError: 'updateError',
  toggleError: 'toggleError',
}

/**
 * @typedef {Object} State
 * Type definition for the state object for the settingsReducer
 * @property {string} errorMessage
 * Any error messages from fetching/updating settings.
 * @property {{text: string, type: string}[]} tenantErrorMessages
 * Any tenant input validation error messages
 * @property {{text: string, type: string}[]} tenantInfoMessages
 * Any tenant input info messages.
 * @property {{text: string, type: string}[]} suffixErrorMessages
 * Any error messages related to the user specified suffix
 * @property {boolean} loading
 * Whether settings are still being loaded or not
 * @property {boolean} uiEnabled
 * Whether the user can interact with the UI.
 * @property {string} microsoft_sync_login_attribute_suffix
 * The suffix that will be appended to the value determined by microsoft_sync_login_attribute.
 * @property {'userPrincipalName' | 'mail' | 'mailNickname'} microsoft_sync_remote_attribute
 * The Azure Active Directory field that will be used to associate Canvas users with Microsoft users.
 * @property {boolean} microsoft_sync_enabled
 * Whether Teams sync is enabled or not
 * @property {string} microsoft_sync_tenant
 * The Microsoft tenant this account wants to use
 * @property {'email'|'preferred_username'|'sis_user_id'} microsoft_sync_login_attribute
 * The attribute to use for mapping Canvas users to Microsoft users.
 * @property {string} successMessage
 * A success message that should be displayed after successfully updating
 * settings
 */

/**
 * @type State
 * The default state for the reducer
 */
export const defaultState = {
  errorMessage: '',
  tenantErrorMessages: [],
  tenantInfoMessages: [],
  suffixErrorMessages: [],
  loading: true,
  uiEnabled: true,
  microsoft_sync_login_attribute_suffix: '',
  microsoft_sync_remote_attribute: 'userPrincipalName',
  microsoft_sync_enabled: false,
  microsoft_sync_tenant: '',
  last_saved_microsoft_sync_tenant: '',
  microsoft_sync_login_attribute: 'email',
  successMessage: '',
}

/**
 * Reducer for the MicrosoftSyncAccountSettings component
 * @param {State} state The previous state
 * @param {Object} obj The object full of necessary info for the reducer
 * @param {ReducerAction} obj.type The action for the reducer to take
 * @param {Object} obj.payload The data for the reducer to use
 * @param {Function} obj.dispatch The dispatch function to trigger this reducer. Used for callbacks
 * @returns {State} The updated state
 */
export function settingsReducer(state, {type, payload, dispatch}) {
  switch (type) {
    case reducerActions.removeAlerts: {
      return {
        ...state,
        errorMessage: '',
        successMessage: '',
      }
    }
    case reducerActions.updateAttribute: {
      return {
        ...state,
        microsoft_sync_login_attribute: payload.microsoft_sync_login_attribute,
      }
    }
    case reducerActions.updateSuffix: {
      return {
        ...state,
        microsoft_sync_login_attribute_suffix: payload.microsoft_sync_login_attribute_suffix,
        suffixErrorMessages: [],
      }
    }
    case reducerActions.updateRemoteAttribute: {
      return {
        ...state,
        microsoft_sync_remote_attribute: payload.microsoft_sync_remote_attribute,
      }
    }
    case reducerActions.updateTenant: {
      const tenantInfoMessages = setTenantInfoMessages(state, payload)

      return {
        ...state,
        microsoft_sync_tenant: payload.microsoft_sync_tenant,
        tenantErrorMessages: [],
        tenantInfoMessages,
      }
    }
    case reducerActions.updateSettings: {
      state.suffixErrorMessages = getSuffixErrorMessages(state)
      state.tenantErrorMessages = getTenantErrorMessages(state)

      if (state.suffixErrorMessages.length === 0 && state.tenantErrorMessages.length === 0) {
        state.uiEnabled = false
        doUpdateSettings(state)
          .then(() => dispatch({type: reducerActions.updateSuccess}))
          .catch(() => dispatch({type: reducerActions.updateError}))
      }

      return {
        ...state,
        errorMessage: '',
        successMessage: '',
      }
    }
    case reducerActions.toggleSync: {
      state.tenantErrorMessages = getTenantErrorMessages(state)
      state.suffixErrorMessages = getSuffixErrorMessages(state)

      if (state.tenantErrorMessages.length === 0 && state.suffixErrorMessages.length === 0) {
        state.microsoft_sync_enabled = !state.microsoft_sync_enabled
        state.uiEnabled = false
        doUpdateSettings(state)
          .then(() => dispatch({type: reducerActions.updateSuccess}))
          .catch(() => dispatch({type: reducerActions.toggleError}))
      }

      return {
        ...state,
        errorMessage: '',
        successMessage: '',
      }
    }
    case reducerActions.fetchSuccess: {
      return {
        ...state,
        ...payload,
        last_saved_microsoft_sync_tenant:
          payload.microsoft_sync_tenant || state.microsoft_sync_tenant,
      }
    }
    case reducerActions.fetchLoading: {
      return {
        ...state,
        loading: payload.loading,
      }
    }
    case reducerActions.fetchError: {
      return {
        ...state,
        errorMessage: I18n.t(
          'Unable to fetch current Microsoft Teams Sync settings. Please check your internet connection. If the problem persists, please contact support.'
        ),
      }
    }
    case reducerActions.updateSuccess: {
      return {
        ...state,
        successMessage: I18n.t('Microsoft Teams Sync settings updated!'),
        uiEnabled: true,
        last_saved_microsoft_sync_tenant: state.microsoft_sync_tenant,
        tenantInfoMessages: [],
      }
    }
    case reducerActions.updateError: {
      return {
        ...state,
        errorMessage: I18n.t(
          'Unable to update Microsoft Teams Sync settings. Please try again. If the issue persists, please contact support.'
        ),
        uiEnabled: true,
      }
    }
    case reducerActions.toggleError: {
      return {
        ...state,
        errorMessage: I18n.t(
          'Unable to update Microsoft Teams Sync settings. Please try again. If the issue persists, please contact support.'
        ),
        microsoft_sync_enabled: !state.microsoft_sync_enabled,
        uiEnabled: true,
      }
    }
  }
}
