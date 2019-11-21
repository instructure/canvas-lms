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

import $ from 'jquery'
import axios from 'axios'
import developerKeysActions from './developerKeysActions'

const actions = {}

actions.LTI_KEYS_SET_LTI_KEY = 'LTI_KEYS_SET_LTI_KEY'
actions.ltiKeysSetLtiKey = payload => ({
  type: actions.LTI_KEYS_SET_LTI_KEY,
  payload
})

actions.LTI_KEYS_SET_CUSTOMIZING = 'LTI_KEYS_SET_CUSTOMIZING'
actions.ltiKeysSetCustomizing = payload => ({
  type: actions.LTI_KEYS_SET_CUSTOMIZING,
  payload
})

actions.LTI_KEYS_SET_ENABLED_SCOPES = 'LTI_KEYS_SET_ENABLED_SCOPES'
actions.ltiKeysSetEnabledScopes = payload => ({
  type: actions.LTI_KEYS_SET_ENABLED_SCOPES,
  payload
})

actions.LTI_KEYS_SET_DISABLED_PLACEMENTS = 'LTI_KEYS_SET_DISABLED_PLACEMENTS'
actions.ltiKeysSetDisabledPlacements = payload => ({
  type: actions.LTI_KEYS_SET_DISABLED_PLACEMENTS,
  payload
})

actions.LTI_KEYS_SET_PRIVACY_LEVEL = 'LTI_KEYS_SET_PRIVACY_LEVEL'
actions.ltiKeysSetPrivacyLevel = payload => ({
  type: actions.LTI_KEYS_SET_PRIVACY_LEVEL,
  payload
})

actions.SET_LTI_TOOL_CONFIGURATION = 'SET_LTI_TOOL_CONFIGURATION'
actions.setLtiToolConfiguration = payload => ({
  type: actions.SET_LTI_TOOL_CONFIGURATION,
  payload
})

actions.SET_LTI_TOOL_CONFIGURATION_URL = 'SET_LTI_TOOL_CONFIGURATION_URL'
actions.setLtiToolConfigurationUrl = payload => ({
  type: actions.SET_LTI_TOOL_CONFIGURATION_URL,
  payload
})

actions.RESET_LTI_STATE = 'RESET_LTI_STATE'
actions.resetLtiState = () => ({type: actions.RESET_LTI_STATE})

actions.SAVE_LTI_TOOL_CONFIGURATION_START = 'SAVE_LTI_TOOL_CONFIGURATION_START'
actions.saveLtiToolConfigurationStart = () => ({
  type: actions.SAVE_LTI_TOOL_CONFIGURATION_START
})

actions.SAVE_LTI_TOOL_CONFIGURATION_FAILED = 'SAVE_LTI_TOOL_CONFIGURATION_FAILED'
actions.saveLtiToolConfigurationFailed = payload => ({
  type: actions.SAVE_LTI_TOOL_CONFIGURATION_FAILED,
  payload
})

actions.SAVE_LTI_TOOL_CONFIGURATION_SUCCESSFUL = 'SAVE_LTI_TOOL_CONFIGURATION_SUCCESSFUL'
actions.saveLtiToolConfigurationSuccessful = payload => ({
  type: actions.SAVE_LTI_TOOL_CONFIGURATION_SUCCESSFUL,
  payload
})

actions.LTI_CONFIGURATION_METHOD = 'LTI_CONFIGURATION_METHOD'
actions.setLtiConfigurationMethod = payload => ({
  type: actions.LTI_CONFIGURATION_METHOD,
  payload
})

actions.saveLtiToolConfiguration = ({
  account_id,
  settings,
  settings_url,
  developer_key
}) => dispatch => {
  dispatch(actions.saveLtiToolConfigurationStart())
  dispatch(developerKeysActions.setEditingDeveloperKey(developer_key))

  if (settings_url) {
    dispatch(actions.setLtiToolConfigurationUrl(settings_url))
  }

  const url = `/api/lti/accounts/${account_id}/developer_keys/tool_configuration`

  return axios
    .post(url, {
      tool_configuration: {
        settings,
        ...(settings_url ? {settings_url} : {})
      },
      developer_key
    })
    .then(response => {
      const newKey = response.data.developer_key
      newKey.tool_configuration = response.data.tool_configuration.settings
      dispatch(actions.saveLtiToolConfigurationSuccessful())
      dispatch(actions.setLtiToolConfiguration(response.data.tool_configuration.settings))
      dispatch(actions.ltiKeysSetCustomizing(true))
      dispatch(developerKeysActions.setEditingDeveloperKey(newKey))
      dispatch(developerKeysActions.listDeveloperKeysPrepend(newKey))
      return response.data
    })
    .catch(error => {
      dispatch(actions.saveLtiToolConfigurationFailed(error))
      dispatch(developerKeysActions.setEditingDeveloperKey(false))
      $.flashError(error.message)
      return error
    })
}

actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS_START = 'LTI_KEYS_UPDATE_CUSTOMIZATIONS_START'
actions.ltiKeysUpdateCustomizationsStart = () => ({
  type: actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS_START
})

actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS_FAILED = 'LTI_KEYS_UPDATE_CUSTOMIZATIONS_FAILED'
actions.ltiKeysUpdateCustomizationsFailed = payload => ({
  type: actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS_FAILED,
  payload
})

actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS_SUCCESSFUL = 'LTI_KEYS_UPDATE_CUSTOMIZATIONS_SUCCESSFUL'
actions.ltiKeysUpdateCustomizationsSuccessful = payload => ({
  type: actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS_SUCCESSFUL,
  payload
})

actions.LTI_KEYS_UPDATE_CUSTOMIZATIONS = 'LTI_KEYS_UPDATE_CUSTOMIZATIONS'
actions.ltiKeysUpdateCustomizations = (
  developerKey,
  disabled_placements,
  developerKeyId,
  toolConfiguration,
  customFields,
  privacyLevel
) => dispatch => {
  dispatch(actions.ltiKeysUpdateCustomizationsStart())
  const url = `/api/lti/developer_keys/${developerKeyId}/tool_configuration`
  return axios
    .put(url, {
      developer_key: {
        name: developerKey.name,
        notes: developerKey.notes,
        email: developerKey.email,
        scopes: developerKey.scopes,
        redirect_uris: developerKey.redirect_uris
      },
      tool_configuration: {
        custom_fields: customFields,
        disabled_placements,
        settings: toolConfiguration,
        privacy_level: privacyLevel
      }
    })
    .then(data => {
      actions.ltiKeysUpdateCustomizationsSuccessful()
      return data.data
    })
    .catch(error => {
      dispatch(actions.ltiKeysUpdateCustomizationsFailed(error))
      $.flashError(error.message)
    })
}

export default actions
