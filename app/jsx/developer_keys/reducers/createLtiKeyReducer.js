/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ACTION_NAMES from '../actions/ltiKeyActions'

const initialState = {
  isLtiKey: false,
  customizing: false,
  saveToolConfigurationPending: false,
  saveToolConfigurationSuccessful: false,
  saveToolConfigurationError: null,
  toolConfiguration: {},
  toolConfigurationUrl: '',
  enabledScopes: [],
  disabledPlacements: [],
  updateCustomizationsPending: false,
  updateCustomizationsSuccessful: false,
  updateCustomizationsError: null
}

const ltiKeysHandlers = {
  [ACTION_NAMES.LTI_KEYS_SET_LTI_KEY]: (state, action) => ({
    ...state,
    isLtiKey: action.payload
  }),
  [ACTION_NAMES.LTI_KEYS_SET_CUSTOMIZING]: (state, action) => ({
    ...state,
    customizing: action.payload
  }),
  [ACTION_NAMES.LTI_KEYS_SET_ENABLED_SCOPES]: (state, action) => ({
    ...state,
    enabledScopes: action.payload
  }),
  [ACTION_NAMES.LTI_KEYS_SET_DISABLED_PLACEMENTS]: (state, action) => ({
    ...state,
    disabledPlacements: action.payload
  }),
  [ACTION_NAMES.SET_LTI_TOOL_CONFIGURATION]: (state, action) => ({
    ...state,
    toolConfiguration: action.payload
  }),
  [ACTION_NAMES.SET_LTI_TOOL_CONFIGURATION_URL]: (state, action) => ({
    ...state,
    toolConfigurationUrl: action.payload
  }),
  [ACTION_NAMES.SAVE_LTI_TOOL_CONFIGURATION_START]: state => ({
    ...state,
    saveToolConfigurationPending: true
  }),
  [ACTION_NAMES.SAVE_LTI_TOOL_CONFIGURATION_FAILED]: (state, action) => ({
    ...state,
    saveToolConfigurationPending: false,
    saveToolConfigurationError: action.payload
  }),
  [ACTION_NAMES.SAVE_LTI_TOOL_CONFIGURATION_SUCCESSFUL]: state => ({
    ...state,
    saveToolConfigurationPending: false,
    saveToolConfigurationError: null,
    saveToolConfigurationSuccessful: true
  }),
  [ACTION_NAMES.RESET_LTI_STATE]: state => ({
    ...state,
    isLtiKey: false,
    customizing: false,
    toolConfiguration: {},
    toolConfigurationUrl: '',
    disabledPlacements: [],
    enabledScopes: []
  }),
  [ACTION_NAMES.LTI_KEYS_UPDATE_CUSTOMIZATIONS_START]: state => ({
    ...state,
    updateCustomizationsPending: true
  }),
  [ACTION_NAMES.LTI_KEYS_UPDATE_CUSTOMIZATIONS_FAILED]: (state, action) => ({
    ...state,
    updateCustomizationsPending: false,
    updateCustomizationsError: action.payload
  }),
  [ACTION_NAMES.LTI_KEYS_UPDATE_CUSTOMIZATIONS_SUCCESSFUL]: state => ({
    ...state,
    updateCustomizationsPending: false,
    updateCustomizationsError: null,
    updateCustomizationsSuccessful: true
  })
}

export default (state = initialState, action) => {
  if (ltiKeysHandlers[action.type]) {
    return ltiKeysHandlers[action.type](state, action)
  } else {
    return state
  }
}
