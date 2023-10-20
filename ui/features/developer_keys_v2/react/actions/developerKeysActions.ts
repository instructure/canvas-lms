// @ts-nocheck
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
import axios from '@canvas/axios'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('react_developer_keys')

const actions: any = {}

actions.LIST_DEVELOPER_KEYS_START = 'LIST_DEVELOPER_KEYS_START'
actions.listDeveloperKeysStart = payload => ({type: actions.LIST_DEVELOPER_KEYS_START, payload})

actions.LIST_DEVELOPER_KEYS_SUCCESSFUL = 'LIST_DEVELOPER_KEYS_SUCCESSFUL'
actions.listDeveloperKeysSuccessful = payload => ({
  type: actions.LIST_DEVELOPER_KEYS_SUCCESSFUL,
  payload,
})

actions.LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL = 'LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL'
actions.listRemainingDeveloperKeysSuccessful = payload => ({
  type: actions.LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL,
  payload,
})

actions.LIST_DEVELOPER_KEYS_FAILED = 'LIST_DEVELOPER_KEYS_FAILED'
actions.listDeveloperKeysFailed = error => ({
  type: actions.LIST_DEVELOPER_KEYS_FAILED,
  error: true,
  payload: error,
})

actions.LIST_INHERITED_DEVELOPER_KEYS_START = 'LIST_INHERITED_DEVELOPER_KEYS_START'
actions.listInheritedDeveloperKeysStart = payload => ({
  type: actions.LIST_INHERITED_DEVELOPER_KEYS_START,
  payload,
})

actions.LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL = 'LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL'
actions.listInheritedDeveloperKeysSuccessful = payload => ({
  type: actions.LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL,
  payload,
})

actions.LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL =
  'LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL'
actions.listRemainingInheritedDeveloperKeysSuccessful = payload => ({
  type: actions.LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL,
  payload,
})

actions.LIST_INHERITED_DEVELOPER_KEYS_FAILED = 'LIST_INHERITED_DEVELOPER_KEYS_FAILED'
actions.listInheritedDeveloperKeysFailed = error => ({
  type: actions.LIST_INHERITED_DEVELOPER_KEYS_FAILED,
  error: true,
  payload: error,
})

actions.LIST_DEVELOPER_KEYS_REPLACE = 'LIST_DEVELOPER_KEYS_REPLACE'
actions.listDeveloperKeysReplace = payload => ({type: actions.LIST_DEVELOPER_KEYS_REPLACE, payload})

actions.LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE = 'LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE'
actions.listDeveloperKeysReplaceBindingState = payload => ({
  type: actions.LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE,
  payload,
})

actions.LIST_DEVELOPER_KEYS_DELETE = 'LIST_DEVELOPER_KEYS_DELETE'
actions.listDeveloperKeysDelete = payload => ({type: actions.LIST_DEVELOPER_KEYS_DELETE, payload})

actions.LIST_DEVELOPER_KEYS_PREPEND = 'LIST_DEVELOPER_KEYS_PREPEND'
actions.listDeveloperKeysPrepend = payload => ({type: actions.LIST_DEVELOPER_KEYS_PREPEND, payload})

actions.DEACTIVATE_DEVELOPER_KEY_START = 'DEACTIVATE_DEVELOPER_KEY_START'
actions.deactivateDeveloperKeyStart = payload => ({
  type: actions.DEACTIVATE_DEVELOPER_KEY_START,
  payload,
})

actions.DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL = 'DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL'
actions.deactivateDeveloperKeySuccessful = payload => ({
  type: actions.DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL,
  payload,
})

actions.DEACTIVATE_DEVELOPER_KEY_FAILED = 'DEACTIVATE_DEVELOPER_KEY_FAILED'
actions.deactivateDeveloperKeyFailed = error => ({
  type: actions.DEACTIVATE_DEVELOPER_KEY_FAILED,
  error: true,
  payload: error,
})

actions.MAKE_VISIBLE_DEVELOPER_KEY_START = 'MAKE_VISIBLE_DEVELOPER_KEY_START'
actions.makeVisibleDeveloperKeyStart = () => ({type: actions.MAKE_VISIBLE_DEVELOPER_KEY_START})

actions.MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL = 'MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL'
actions.makeVisibleDeveloperKeySuccessful = () => ({
  type: actions.MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL,
})

actions.MAKE_VISIBLE_DEVELOPER_KEY_FAILED = 'MAKE_VISIBLE_DEVELOPER_KEY_FAILED'
actions.makeVisibleDeveloperKeyFailed = error => ({
  type: actions.MAKE_VISIBLE_DEVELOPER_KEY_FAILED,
  error: true,
  payload: error,
})

actions.MAKE_INVISIBLE_DEVELOPER_KEY_START = 'MAKE_INVISIBLE_DEVELOPER_KEY_START'
actions.makeInvisibleDeveloperKeyStart = () => ({type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_START})

actions.MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL = 'MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL'
actions.makeInvisibleDeveloperKeySuccessful = () => ({
  type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL,
})

actions.MAKE_INVISIBLE_DEVELOPER_KEY_FAILED = 'MAKE_INVISIBLE_DEVELOPER_KEY_FAILED'
actions.makeInvisibleDeveloperKeyFailed = error => ({
  type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_FAILED,
  error: true,
  payload: error,
})

actions.DELETE_DEVELOPER_KEY_START = 'DELETE_DEVELOPER_KEY_START'
actions.deleteDeveloperKeyStart = payload => ({type: actions.DELETE_DEVELOPER_KEY_START, payload})

actions.DELETE_DEVELOPER_KEY_SUCCESSFUL = 'DELETE_DEVELOPER_KEY_SUCCESSFUL'
actions.deleteDeveloperKeySuccessful = payload => ({
  type: actions.DELETE_DEVELOPER_KEY_SUCCESSFUL,
  payload,
})

actions.DELETE_DEVELOPER_KEY_FAILED = 'DELETE_DEVELOPER_KEY_FAILED'
actions.deleteDeveloperKeyFailed = error => ({
  type: actions.DELETE_DEVELOPER_KEY_FAILED,
  error: true,
  payload: error,
})

actions.ACTIVATE_DEVELOPER_KEY_START = 'ACTIVATE_DEVELOPER_KEY_START'
actions.activateDeveloperKeyStart = payload => ({
  type: actions.ACTIVATE_DEVELOPER_KEY_START,
  payload,
})

actions.ACTIVATE_DEVELOPER_KEY_SUCCESSFUL = 'ACTIVATE_DEVELOPER_KEY_SUCCESSFUL'
actions.activateDeveloperKeySuccessful = payload => ({
  type: actions.ACTIVATE_DEVELOPER_KEY_SUCCESSFUL,
  payload,
})

actions.ACTIVATE_DEVELOPER_KEY_FAILED = 'ACTIVATE_DEVELOPER_KEY_FAILED'
actions.activateDeveloperKeyFailed = error => ({
  type: actions.ACTIVATE_DEVELOPER_KEY_FAILED,
  error: true,
  payload: error,
})

actions.CREATE_OR_EDIT_DEVELOPER_KEY_START = 'CREATE_OR_EDIT_DEVELOPER_KEY_START'
actions.createOrEditDeveloperKeyStart = () => ({type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_START})

actions.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL = 'CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL'
actions.createOrEditDeveloperKeySuccessful = () => ({
  type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL,
})

actions.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED = 'CREATE_OR_EDIT_DEVELOPER_KEY_FAILED'
actions.createOrEditDeveloperKeyFailed = () => ({type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED})

actions.SET_EDITING_DEVELOPER_KEY = 'SET_EDITING_DEVELOPER_KEY'
actions.setEditingDeveloperKey = payload => ({type: actions.SET_EDITING_DEVELOPER_KEY, payload})

actions.editDeveloperKey = payload => dispatch => {
  if (payload) {
    dispatch(actions.listDeveloperKeyScopesSet(payload.scopes))
  }
  dispatch(actions.setEditingDeveloperKey(payload))
}

actions.DEVELOPER_KEYS_MODAL_OPEN = 'DEVELOPER_KEYS_MODAL_OPEN'
actions.developerKeysModalOpen = (type = 'api') => {
  window.location.hash = `${type}_key_modal_opened`
  return {type: actions.DEVELOPER_KEYS_MODAL_OPEN}
}

actions.DEVELOPER_KEYS_MODAL_CLOSE = 'DEVELOPER_KEYS_MODAL_CLOSE'
actions.developerKeysModalClose = () => {
  window.location.hash = ''
  return {type: actions.DEVELOPER_KEYS_MODAL_CLOSE}
}

actions.SET_BINDING_WORKFLOW_STATE_START = 'SET_BINDING_WORKFLOW_STATE_START'
actions.setBindingWorkflowStateStart = () => ({type: actions.SET_BINDING_WORKFLOW_STATE_START})

actions.SET_BINDING_WORKFLOW_STATE_SUCCESSFUL = 'SET_BINDING_WORKFLOW_STATE_SUCCESSFUL'
actions.setBindingWorkflowStateSuccessful = response => ({
  type: actions.SET_BINDING_WORKFLOW_STATE_SUCCESSFUL,
  payload: response,
})

actions.SET_BINDING_WORKFLOW_STATE_FAILED = 'SET_BINDING_WORKFLOW_STATE_FAILED'
actions.setBindingWorkflowStateFailed = payload => ({
  type: actions.SET_BINDING_WORKFLOW_STATE_FAILED,
  payload,
})

actions.LIST_DEVELOPER_KEY_SCOPES_FAILED = 'LIST_DEVELOPER_KEY_SCOPES_FAILED'
actions.listDeveloperKeyScopesFailed = () => ({type: actions.LIST_DEVELOPER_KEY_SCOPES_FAILED})

actions.LIST_DEVELOPER_KEY_SCOPES_START = 'LIST_DEVELOPER_KEY_SCOPES_START'
actions.listDeveloperKeyScopesStart = () => ({type: actions.LIST_DEVELOPER_KEY_SCOPES_START})

actions.LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL = 'LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL'
actions.listDeveloperKeyScopesSuccessful = payload => ({
  type: actions.LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL,
  payload,
})

actions.LIST_DEVELOPER_KEY_SCOPES_FAILED = 'LIST_DEVELOPER_KEY_SCOPES_FAILED'
actions.listDeveloperKeyScopesFailed = () => ({type: actions.LIST_DEVELOPER_KEY_SCOPES_FAILED})

actions.LIST_DEVELOPER_KEY_SCOPES_SET = 'LIST_DEVELOPER_KEY_SCOPES_SET'
actions.listDeveloperKeyScopesSet = selectedScopes => ({
  type: actions.LIST_DEVELOPER_KEY_SCOPES_SET,
  payload: selectedScopes,
})

actions.listDeveloperKeyScopes = accountId => dispatch => {
  dispatch(actions.listDeveloperKeyScopesStart())
  const url = `/api/v1/accounts/${accountId}/scopes?group_by=resource_name`

  axios
    .get(url)
    .then(response => {
      dispatch(actions.listDeveloperKeyScopesSuccessful(response.data))
    })
    .catch(error => {
      dispatch(actions.listDeveloperKeyScopesFailed())
      $.flashError(error.message)
    })
}

actions.setBindingWorkflowState = (developerKey, accountId, workflowState) => dispatch => {
  dispatch(actions.setBindingWorkflowStateStart())
  const url = `/api/v1/accounts/${accountId}/developer_keys/${developerKey.id}/developer_key_account_bindings`

  const previousAccountBinding = developerKey.developer_key_account_binding || {}

  dispatch(
    actions.listDeveloperKeysReplaceBindingState({
      developerKeyId: developerKey.id,
      newAccountBinding: {...previousAccountBinding, workflow_state: workflowState},
    })
  )
  axios
    .post(url, {
      developer_key_account_binding: {
        workflow_state: workflowState,
      },
    })
    .then(response => {
      dispatch(actions.setBindingWorkflowStateSuccessful(response.data))
    })
    .catch(error => {
      dispatch(
        actions.setBindingWorkflowStateFailed({
          developerKeyId: developerKey.id,
          previousAccountBinding,
        })
      )
      $.flashError(error.message)
    })
}

actions.createOrEditDeveloperKey = (formData, url, method) => dispatch => {
  dispatch(actions.createOrEditDeveloperKeyStart())

  return axios({
    method,
    url,
    data: formData,
  })
    .then(response => {
      if (method === 'post') {
        dispatch(actions.listDeveloperKeysPrepend(response.data))
      } else {
        dispatch(actions.listDeveloperKeysReplace(response.data))
      }
      dispatch(actions.createOrEditDeveloperKeySuccessful())
    })
    .catch(error => {
      $.flashError(error.message)
      dispatch(actions.createOrEditDeveloperKeyFailed())
    })
    .finally(() => {
      dispatch(actions.editDeveloperKey())
    })
}

const inherited = 'inherited=true'

function retrieveDevKeys({url, dispatch, success, failure}) {
  axios
    .get(url)
    .then(response => {
      const {next} = parseLinkHeader(response.headers.link)
      const payload = {next, developerKeys: response.data}
      dispatch(success(payload))
    })
    .catch(err => dispatch(failure(err)))
}

actions.getDeveloperKeys = (url, newSearch) => (dispatch, _getState) => {
  dispatch(actions.listDeveloperKeysStart(newSearch))

  retrieveDevKeys({
    url,
    dispatch,
    success: actions.listDeveloperKeysSuccessful,
    failure: actions.listDeveloperKeysFailed,
  })
  retrieveDevKeys({
    url: `${url}?${inherited}`,
    dispatch,
    success: actions.listInheritedDeveloperKeysSuccessful,
    failure: actions.listInheritedDeveloperKeysFailed,
  })
}

function retrieveRemainingDevKeys({
  url,
  developerKeysPassedIn,
  dispatch,
  retrieve,
  success,
  failure,
  callback,
}) {
  return axios
    .get(url)
    .then(response => {
      const {next} = parseLinkHeader(response.headers.link)
      const developerKeys = developerKeysPassedIn.concat(response.data)
      if (next) {
        dispatch(retrieve(next, developerKeys, callback))
      } else {
        const payload = {next, developerKeys}
        dispatch(success(payload))
        if (callback) {
          // eslint-disable-next-line promise/no-callback-in-promise
          callback(payload.developerKeys)
        }
        return payload
      }
    })
    .catch(err => dispatch(failure(err)))
}

actions.getRemainingDeveloperKeys = (url, developerKeysPassedIn, callback) => dispatch => {
  dispatch(actions.listDeveloperKeysStart())

  return retrieveRemainingDevKeys({
    url,
    developerKeysPassedIn,
    dispatch,
    retrieve: actions.getRemainingDeveloperKeys,
    success: actions.listRemainingDeveloperKeysSuccessful,
    failure: actions.listDeveloperKeysFailed,
    callback,
  })
}

actions.getRemainingInheritedDeveloperKeys = (url, developerKeysPassedIn, callback) => dispatch => {
  dispatch(actions.listInheritedDeveloperKeysStart())

  return retrieveRemainingDevKeys({
    url: `${url}?${inherited}`,
    developerKeysPassedIn,
    dispatch,
    retrieve: actions.getRemainingInheritedDeveloperKeys,
    success: actions.listRemainingInheritedDeveloperKeysSuccessful,
    failure: actions.listInheritedDeveloperKeysFailed,
    callback,
  })
}

actions.deactivateDeveloperKey = developerKey => (dispatch, _getState) => {
  dispatch(actions.deactivateDeveloperKeyStart())

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios
    .put(url, {
      developer_key: {event: 'deactivate'},
    })
    .then(response => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.deactivateDeveloperKeySuccessful())
    })
    .catch(err => dispatch(actions.deactivateDeveloperKeyFailed(err)))
}

actions.activateDeveloperKey = developerKey => (dispatch, _getState) => {
  dispatch(actions.activateDeveloperKeyStart())

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios
    .put(url, {
      developer_key: {event: 'activate'},
    })
    .then(response => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.activateDeveloperKeySuccessful())
    })
    .catch(err => dispatch(actions.activateDeveloperKeyFailed(err)))
}

actions.makeInvisibleDeveloperKey = developerKey => (dispatch, _getState) => {
  dispatch(actions.makeInvisibleDeveloperKeyStart())

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios
    .put(url, {
      developer_key: {visible: false},
    })
    .then(response => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.makeInvisibleDeveloperKeySuccessful())
    })
    .catch(err => dispatch(actions.makeInvisibleDeveloperKeyFailed(err)))
}

actions.makeVisibleDeveloperKey = developerKey => (dispatch, _getState) => {
  dispatch(actions.makeVisibleDeveloperKeyStart())

  const url = `/api/v1/developer_keys/${developerKey.id}`
  axios
    .put(url, {
      developer_key: {visible: true},
    })
    .then(response => {
      dispatch(actions.listDeveloperKeysReplace(response.data))
      dispatch(actions.makeVisibleDeveloperKeySuccessful())
    })
    .catch(err => dispatch(actions.makeVisibleDeveloperKeyFailed(err)))
}

actions.deleteDeveloperKey = developerKey => dispatch => {
  dispatch(actions.deleteDeveloperKeyStart())

  const url = `/api/v1/developer_keys/${developerKey.id}`
  return axios
    .delete(url)
    .then(response => {
      dispatch(actions.listDeveloperKeysDelete(response.data))
      dispatch(actions.deleteDeveloperKeySuccessful())
    })
    .catch(err => dispatch(actions.deleteDeveloperKeyFailed(err)))
}

actions.LTI_KEYS_SET_LTI_KEY = 'LTI_KEYS_SET_LTI_KEY'
actions.ltiKeysSetLtiKey = payload => ({
  type: actions.LTI_KEYS_SET_LTI_KEY,
  payload,
})

actions.RESET_LTI_STATE = 'RESET_LTI_STATE'
actions.resetLtiState = () => ({type: actions.RESET_LTI_STATE})

actions.saveLtiToolConfiguration =
  ({account_id, settings, settings_url, developer_key}) =>
  dispatch => {
    dispatch(actions.setEditingDeveloperKey(developer_key))

    const url = `/api/lti/accounts/${account_id}/developer_keys/tool_configuration`

    return axios
      .post(url, {
        tool_configuration: {
          settings,
          ...(settings_url ? {settings_url} : {}),
        },
        developer_key,
      })
      .then(response => {
        const newKey = response.data.developer_key
        newKey.tool_configuration = response.data.tool_configuration.settings
        dispatch(actions.setEditingDeveloperKey(newKey))
        dispatch(actions.listDeveloperKeysPrepend(newKey))
        return response.data
      })
      .catch(err => {
        const errors = err.response.data.errors
        for (const error of errors) {
          const {field, message} = error
          if (field === 'configuration') {
            const title = I18n.t('Configuration error')
            $.flashError(`${title}: ${message}`)
          } else {
            $.flashError(error.message)
          }
        }
        dispatch(actions.setEditingDeveloperKey(false))
        throw err
      })
  }

actions.updateLtiKey = (
  developerKey,
  disabled_placements,
  developerKeyId,
  toolConfiguration,
  customFields
) => {
  const url = `/api/lti/developer_keys/${developerKeyId}/tool_configuration`
  return axios
    .put(url, {
      developer_key: {
        name: developerKey.name,
        notes: developerKey.notes,
        email: developerKey.email,
        scopes: developerKey.scopes,
        redirect_uris: developerKey.redirect_uris,
      },
      tool_configuration: {
        custom_fields: customFields,
        disabled_placements,
        settings: toolConfiguration,
      },
    })
    .then(data => {
      return data.data
    })
    .catch(err => {
      const errors = err.response.data.errors
      for (const error of errors) {
        const {field, message} = error
        if (field === 'configuration') {
          const title = I18n.t('Configuration error')
          $.flashError(`${title}: ${message}`)
        } else {
          $.flashError(error.message)
        }
      }
      throw err
    })
}

export default actions
