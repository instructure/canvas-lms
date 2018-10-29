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

import actions from 'jsx/developer_keys/actions/ltiKeyActions'
import reducer from 'jsx/developer_keys/reducers/createLtiKeyReducer'

function freshState() {
  return {
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
    updateCustomizationsError: null,
  }
}

it('sets the defaults', () => {
  const defaults = reducer(undefined, {})
  expect(defaults.isLtiKey).toEqual(false)
  expect(defaults.customizing).toEqual(false)
  expect(defaults.toolConfiguration).toEqual({})
  expect(defaults.disabledPlacements).toEqual([])
  expect(defaults.enabledScopes).toEqual([])
  expect(defaults.updateCustomizationsPending).toEqual(false)
  expect(defaults.updateCustomizationsSuccessful).toEqual(false)
  expect(defaults.updateCustomizationsError).toBeNull()
})

it('handles "LTI_KEYS_SET_LTI_KEY"', () => {
  const state = freshState()
  const action = actions.ltiKeysSetLtiKey(true)
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(true)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toBeNull()
})

it('handles "LTI_KEYS_SET_CUSTOMIZING"', () => {
  const state = freshState()
  const action = actions.ltiKeysSetCustomizing(true)
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(true)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toBeNull()
})

it('handles "LTI_KEYS_SET_ENABLED_SCOPES"', () => {
  const state = freshState()
  const action = actions.ltiKeysSetEnabledScopes(['cool scope'])
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual(['cool scope'])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toBeNull()
})

it('handles "LTI_KEYS_SET_DISABLED_PLACEMENTS"', () => {
  const state = freshState()
  const action = actions.ltiKeysSetDisabledPlacements(['account_navigation'])
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual(['account_navigation'])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toBeNull()
})

it('handles "SET_LTI_TOOL_CONFIGURATION"', () => {
  const state = freshState()
  const config = {test: 'config'}
  const action = actions.setLtiToolConfiguration(config)
  const newState = reducer(state, action)

  expect(newState.toolConfiguration).toEqual(config)
})

it('handles "SET_LTI_TOOL_CONFIGURATION_URL"', () => {
  const state = freshState()
  const configUrl = 'config.url'
  const action = actions.setLtiToolConfigurationUrl(configUrl)
  const newState = reducer(state, action)

  expect(newState.toolConfigurationUrl).toEqual(configUrl)
})
it('handles "SAVE_LTI_TOOL_CONFIGURATION_START"', () => {
  const state = freshState()
  const action = actions.saveLtiToolConfigurationStart()
  const newState = reducer(state, action)

  expect(newState.saveToolConfigurationPending).toEqual(true)
})

it('handles "SAVE_LTI_TOOL_CONFIGURATION_ERROR"', () => {
  const state = freshState()
  const error = new Error('error')
  const action = actions.saveLtiToolConfigurationFailed(error)
  const newState = reducer(state, action)

  expect(newState.saveToolConfigurationPending).toEqual(false)
  expect(newState.saveToolConfigurationError).toEqual(error)
})

it('handles "SAVE_LTI_TOOL_CONFIGURATION_SUCCESSFUL"', () => {
  const state = freshState()
  const action = actions.saveLtiToolConfigurationSuccessful()
  const newState = reducer(state, action)

  expect(newState.saveToolConfigurationPending).toEqual(false)
  expect(newState.saveToolConfigurationError).toBeNull()
  expect(newState.saveToolConfigurationSuccessful).toEqual(true)
})

it('handles "LTI_KEYS_UPDATE_CUSTOMIZATIONS_START"', () => {
  const state = freshState()
  const action = actions.ltiKeysUpdateCustomizationsStart()
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(true)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toBeNull()
})

it('handles "LTI_KEYS_UPDATE_CUSTOMIZATIONS_FAILED"', () => {
  const state = freshState()
  const action = actions.ltiKeysUpdateCustomizationsFailed('Error message')
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toEqual('Error message')
})

it('handles "LTI_KEYS_UPDATE_CUSTOMIZATIONS_SUCCESSFUL"', () => {
  const state = freshState()
  const action = actions.ltiKeysUpdateCustomizationsSuccessful()
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(true)
  expect(newState.updateCustomizationsError).toBeNull()
})

it('handles "RESET_LTI_STATE"', () => {
  const state = freshState()
  const action = actions.resetLtiState()
  const newState = reducer(state, action)

  expect(newState.isLtiKey).toEqual(false)
  expect(newState.customizing).toEqual(false)
  expect(newState.toolConfiguration).toEqual({})
  expect(newState.disabledPlacements).toEqual([])
  expect(newState.enabledScopes).toEqual([])
  expect(newState.updateCustomizationsPending).toEqual(false)
  expect(newState.updateCustomizationsSuccessful).toEqual(false)
  expect(newState.updateCustomizationsError).toBeNull()
})
