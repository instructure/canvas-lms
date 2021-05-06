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

import {doUpdateSettings, validateTenant} from './settingsHelper'
import I18n from 'i18n!account_settings_jsx_bundle'

/**
 * @typedef {Object} ReducerAction
 * @property {string} fetchSuccess
 * @property {string} fetchError
 * @property {string} fetchLoading
 * @property {string} updateSettings
 * @property {string} toggleSync
 * @property {string} updateTenant
 * @property {string} updateAttribute
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
  updateTenant: 'updateTenant',
  updateAttribute: 'updateAttribute',
  removeAlerts: 'removeAlerts',
  updateSuccess: 'updateSuccess',
  updateError: 'updateError',
  toggleError: 'toggleError'
}

/**
 * @typedef {Object} State
 * Type definition for the state object for the settingsReducer
 * @property {string} errorMessage
 * Any error messages from fetching/updating settings.
 * @property {string[]} tenantErrorMessages
 * Any tenant input validation error messages
 * @property {boolean} loading
 * Whether settings are still being loaded or not
 * @property {boolean} microsoft_sync_enabled
 * Whether Teams sync is enabled or not
 * @property {string} microsoft_sync_tenant
 * The Microsoft tenant this account wants to use
 * @property {'email'|'preferred_username'|'sis_user_id'} microsoft_sync_login_attribute
 * The attribute to use for mapping Canvas users to Microsoft users.
 * @property {string} selectedAttribute
 * The attribute the user has selected, in their language
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
  loading: true,
  microsoft_sync_enabled: false,
  microsoft_sync_tenant: '',
  microsoft_sync_login_attribute: 'email',
  selectedAttribute: 'email',
  successMessage: ''
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
        successMessage: ''
      }
    }
    case reducerActions.updateAttribute: {
      // Gotta keep track of both the actual login attribute and the selected one
      // cause of i18n.
      return {
        ...state,
        microsoft_sync_login_attribute: payload.microsoft_sync_login_attribute,
        selectedAttribute: payload.selectedAttribute
      }
    }
    case reducerActions.updateTenant: {
      return {
        ...state,
        microsoft_sync_tenant: payload.microsoft_sync_tenant
      }
    }
    case reducerActions.updateSettings: {
      const stateAfterUpdate = validateTenant({...state})
      if (stateAfterUpdate.tenantErrorMessages.length > 0) {
        return stateAfterUpdate
      } else {
        doUpdateSettings(
          stateAfterUpdate.microsoft_sync_enabled,
          stateAfterUpdate.microsoft_sync_tenant,
          stateAfterUpdate.microsoft_sync_login_attribute
        )
          .then(() => dispatch({type: reducerActions.updateSuccess}))
          .catch(() => dispatch({type: reducerActions.updateError}))

        return stateAfterUpdate
      }
    }
    case reducerActions.toggleSync: {
      const stateAfterToggle = validateTenant({...state})

      if (stateAfterToggle.tenantErrorMessages.length > 0) {
        return stateAfterToggle
      } else {
        stateAfterToggle.microsoft_sync_enabled = !state.microsoft_sync_enabled
        doUpdateSettings(
          stateAfterToggle.microsoft_sync_enabled,
          stateAfterToggle.microsoft_sync_tenant,
          stateAfterToggle.microsoft_sync_login_attribute
        )
          .then(() => dispatch({type: reducerActions.updateSuccess}))
          .catch(() => dispatch({type: reducerActions.toggleError}))

        return stateAfterToggle
      }
    }
    case reducerActions.fetchSuccess: {
      // The conditional assignment ensures we don't override our sensible defaults if the account
      // doesn't have sensible settings cause they've never enabled MSFT Teams sync before.
      const selectedLoginAttribute =
        payload.microsoft_sync_login_attribute || state.microsoft_sync_login_attribute

      return {
        ...state,
        microsoft_sync_enabled: payload.microsoft_sync_enabled || state.microsoft_sync_enabled,
        microsoft_sync_tenant: payload.microsoft_sync_tenant || state.microsoft_sync_tenant,
        microsoft_sync_login_attribute: selectedLoginAttribute,
        selectedAttribute: selectedLoginAttribute
      }
    }
    case reducerActions.fetchLoading: {
      return {
        ...state,
        loading: payload.loading
      }
    }
    case reducerActions.fetchError: {
      return {
        ...state,
        errorMessage: I18n.t(
          'Unable to fetch current Microsoft Teams Sync settings. Please check your internet connection. If the problem persists, please contact support.'
        )
      }
    }
    case reducerActions.updateSuccess: {
      return {
        ...state,
        successMessage: I18n.t('Microsoft Teams Sync settings updated!')
      }
    }
    case reducerActions.updateError: {
      return {
        ...state,
        errorMessage: I18n.t(
          'Unable to update Microsoft Teams Sync settings. Please try again. If the issue persists, please contact support.'
        )
      }
    }
    case reducerActions.toggleError: {
      return {
        ...state,
        errorMessage: I18n.t(
          'Unable to update Microsoft Teams Sync settings. Please try again. If the issue persists, please contact support.'
        ),
        microsoft_sync_enabled: !state.microsoft_sync_enabled
      }
    }
  }
}
