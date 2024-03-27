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

import axios from '@canvas/axios'
import {useScope as useI18nScope} from '@canvas/i18n'
import {LtiScope} from 'features/developer_keys_v2/model/LtiScopes'
import $ from 'jquery'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import {AnyAction, Dispatch} from 'redux'
import {DeveloperKey, DeveloperKeyAccountBinding} from '../../model/api/DeveloperKey'
import type {LtiToolConfiguration} from 'features/developer_keys_v2/model/api/LtiToolConfiguration'

const I18n = useI18nScope('react_developer_keys')

export type LtiDeveloperKeyApiResponse = {
  developer_key: DeveloperKey
  tool_configuration: LtiToolConfiguration
  warning_message?: string
}
/**
 * Type function that takes a action type name in all caps and snake case
 * and converts it to a camel case action creator name.
 * @example
 * type Foo = ToActionCreatorName<'FOO_BAR'>
 * Foo // 'fooBar'
 */
export type ToActionCreatorName<K> = ToActionCreatorNameInner<K, true>
export type ToActionCreatorNameInner<
  ActionType extends string,
  IsFirstSegment extends boolean = false
> = ActionType extends `${infer SegmentHead}_${infer SegmentTail}`
  ? `${IsFirstSegment extends true
      ? Lowercase<SegmentHead>
      : Capitalize<Lowercase<SegmentHead>>}${ToActionCreatorNameInner<SegmentTail, false>}`
  : IsFirstSegment extends true
  ? Lowercase<ActionType>
  : Capitalize<Lowercase<ActionType>>

export type DeveloperKeyActionNames =
  | 'LIST_DEVELOPER_KEYS_START'
  | 'LIST_DEVELOPER_KEYS_START'
  | 'LIST_DEVELOPER_KEYS_SUCCESSFUL'
  | 'LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL'
  | 'LIST_DEVELOPER_KEYS_FAILED'
  | 'LIST_INHERITED_DEVELOPER_KEYS_START'
  | 'LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL'
  | 'LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL'
  | 'LIST_INHERITED_DEVELOPER_KEYS_FAILED'
  | 'LIST_DEVELOPER_KEYS_REPLACE'
  | 'LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE'
  | 'LIST_DEVELOPER_KEYS_DELETE'
  | 'LIST_DEVELOPER_KEYS_PREPEND'
  | 'DEACTIVATE_DEVELOPER_KEY_START'
  | 'DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL'
  | 'DEACTIVATE_DEVELOPER_KEY_FAILED'
  | 'MAKE_VISIBLE_DEVELOPER_KEY_START'
  | 'MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL'
  | 'MAKE_VISIBLE_DEVELOPER_KEY_FAILED'
  | 'MAKE_INVISIBLE_DEVELOPER_KEY_START'
  | 'MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL'
  | 'MAKE_INVISIBLE_DEVELOPER_KEY_FAILED'
  | 'DELETE_DEVELOPER_KEY_START'
  | 'DELETE_DEVELOPER_KEY_SUCCESSFUL'
  | 'DELETE_DEVELOPER_KEY_FAILED'
  | 'ACTIVATE_DEVELOPER_KEY_START'
  | 'ACTIVATE_DEVELOPER_KEY_SUCCESSFUL'
  | 'ACTIVATE_DEVELOPER_KEY_FAILED'
  | 'CREATE_OR_EDIT_DEVELOPER_KEY_START'
  | 'CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL'
  | 'CREATE_OR_EDIT_DEVELOPER_KEY_FAILED'
  | 'SET_EDITING_DEVELOPER_KEY'
  | 'DEVELOPER_KEYS_MODAL_OPEN'
  | 'DEVELOPER_KEYS_MODAL_CLOSE'
  | 'SET_BINDING_WORKFLOW_STATE_START'
  | 'SET_BINDING_WORKFLOW_STATE_SUCCESSFUL'
  | 'SET_BINDING_WORKFLOW_STATE_FAILED'
  | 'LIST_DEVELOPER_KEY_SCOPES_FAILED'
  | 'LIST_DEVELOPER_KEY_SCOPES_START'
  | 'LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL'
  | 'LIST_DEVELOPER_KEY_SCOPES_SET'
  | 'LTI_KEYS_SET_LTI_KEY'
  | 'RESET_LTI_STATE'

export const actions = {
  LIST_DEVELOPER_KEYS_START: 'LIST_DEVELOPER_KEYS_START',
  listDeveloperKeysStart: (payload: boolean) => ({
    type: actions.LIST_DEVELOPER_KEYS_START,
    payload,
  }),

  LIST_DEVELOPER_KEYS_SUCCESSFUL: 'LIST_DEVELOPER_KEYS_SUCCESSFUL',
  listDeveloperKeysSuccessful: (payload: {developerKeys: DeveloperKey[]; next?: string}) => {
    return {
      type: actions.LIST_DEVELOPER_KEYS_SUCCESSFUL,
      payload,
    }
  },

  LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL: 'LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL',
  listRemainingDeveloperKeysSuccessful: (payload: {
    developerKeys: DeveloperKey[]
    next?: string
  }) => ({
    type: actions.LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL,
    payload,
  }),

  LIST_DEVELOPER_KEYS_FAILED: 'LIST_DEVELOPER_KEYS_FAILED',
  listDeveloperKeysFailed: (error: unknown) => ({
    type: actions.LIST_DEVELOPER_KEYS_FAILED,
    error: true,
    payload: error,
  }),

  LIST_INHERITED_DEVELOPER_KEYS_START: 'LIST_INHERITED_DEVELOPER_KEYS_START',
  listInheritedDeveloperKeysStart: (payload: unknown) => ({
    type: actions.LIST_INHERITED_DEVELOPER_KEYS_START,
    payload,
  }),

  LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL: 'LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL',
  listInheritedDeveloperKeysSuccessful: (payload: {
    developerKeys: DeveloperKey[]
    next?: string
  }) => ({
    type: actions.LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL,
    payload,
  }),

  LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL:
    'LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL',
  listRemainingInheritedDeveloperKeysSuccessful: (payload: {
    developerKeys: DeveloperKey[]
    next?: string
  }) => ({
    type: actions.LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL,
    payload,
  }),

  LIST_INHERITED_DEVELOPER_KEYS_FAILED: 'LIST_INHERITED_DEVELOPER_KEYS_FAILED',
  listInheritedDeveloperKeysFailed: (error: unknown) => ({
    type: actions.LIST_INHERITED_DEVELOPER_KEYS_FAILED,
    error: true,
    payload: error,
  }),

  LIST_DEVELOPER_KEYS_REPLACE: 'LIST_DEVELOPER_KEYS_REPLACE',
  listDeveloperKeysReplace: (payload: DeveloperKey) => ({
    type: actions.LIST_DEVELOPER_KEYS_REPLACE,
    payload,
  }),

  LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE: 'LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE',
  listDeveloperKeysReplaceBindingState: (payload: {
    developerKeyId: string
    newAccountBinding: DeveloperKeyAccountBinding
  }) => ({
    type: actions.LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE,
    payload,
  }),

  LIST_DEVELOPER_KEYS_DELETE: 'LIST_DEVELOPER_KEYS_DELETE',
  listDeveloperKeysDelete: (payload: DeveloperKey) => ({
    type: actions.LIST_DEVELOPER_KEYS_DELETE,
    payload,
  }),

  LIST_DEVELOPER_KEYS_PREPEND: 'LIST_DEVELOPER_KEYS_PREPEND',
  listDeveloperKeysPrepend: (payload: DeveloperKey) => ({
    type: actions.LIST_DEVELOPER_KEYS_PREPEND,
    payload,
  }),

  DEACTIVATE_DEVELOPER_KEY_START: 'DEACTIVATE_DEVELOPER_KEY_START',
  deactivateDeveloperKeyStart: (payload: unknown) => ({
    type: actions.DEACTIVATE_DEVELOPER_KEY_START,
    payload,
  }),

  DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL: 'DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL',
  deactivateDeveloperKeySuccessful: (payload: unknown) => ({
    type: actions.DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL,
    payload,
  }),

  DEACTIVATE_DEVELOPER_KEY_FAILED: 'DEACTIVATE_DEVELOPER_KEY_FAILED',
  deactivateDeveloperKeyFailed: (error: unknown) => ({
    type: actions.DEACTIVATE_DEVELOPER_KEY_FAILED,
    error: true,
    payload: error,
  }),

  MAKE_VISIBLE_DEVELOPER_KEY_START: 'MAKE_VISIBLE_DEVELOPER_KEY_START',
  makeVisibleDeveloperKeyStart: () => ({type: actions.MAKE_VISIBLE_DEVELOPER_KEY_START}),

  MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL: 'MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL',
  makeVisibleDeveloperKeySuccessful: () => ({
    type: actions.MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL,
  }),

  MAKE_VISIBLE_DEVELOPER_KEY_FAILED: 'MAKE_VISIBLE_DEVELOPER_KEY_FAILED',
  makeVisibleDeveloperKeyFailed: (error: unknown) => ({
    type: actions.MAKE_VISIBLE_DEVELOPER_KEY_FAILED,
    error: true,
    payload: error,
  }),

  MAKE_INVISIBLE_DEVELOPER_KEY_START: 'MAKE_INVISIBLE_DEVELOPER_KEY_START',
  makeInvisibleDeveloperKeyStart: () => ({type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_START}),

  MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL: 'MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL',
  makeInvisibleDeveloperKeySuccessful: () => ({
    type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_SUCCESSFUL,
  }),

  MAKE_INVISIBLE_DEVELOPER_KEY_FAILED: 'MAKE_INVISIBLE_DEVELOPER_KEY_FAILED',
  makeInvisibleDeveloperKeyFailed: (error: unknown) => ({
    type: actions.MAKE_INVISIBLE_DEVELOPER_KEY_FAILED,
    error: true,
    payload: error,
  }),

  DELETE_DEVELOPER_KEY_START: 'DELETE_DEVELOPER_KEY_START',
  deleteDeveloperKeyStart: (payload: unknown) => ({
    type: actions.DELETE_DEVELOPER_KEY_START,
    payload,
  }),

  DELETE_DEVELOPER_KEY_SUCCESSFUL: 'DELETE_DEVELOPER_KEY_SUCCESSFUL',
  deleteDeveloperKeySuccessful: (payload: unknown) => ({
    type: actions.DELETE_DEVELOPER_KEY_SUCCESSFUL,
    payload,
  }),

  DELETE_DEVELOPER_KEY_FAILED: 'DELETE_DEVELOPER_KEY_FAILED',
  deleteDeveloperKeyFailed: (error: unknown) => ({
    type: actions.DELETE_DEVELOPER_KEY_FAILED,
    error: true,
    payload: error,
  }),

  ACTIVATE_DEVELOPER_KEY_START: 'ACTIVATE_DEVELOPER_KEY_START',
  activateDeveloperKeyStart: (payload: unknown) => ({
    type: actions.ACTIVATE_DEVELOPER_KEY_START,
    payload,
  }),

  ACTIVATE_DEVELOPER_KEY_SUCCESSFUL: 'ACTIVATE_DEVELOPER_KEY_SUCCESSFUL',
  activateDeveloperKeySuccessful: (payload: unknown) => ({
    type: actions.ACTIVATE_DEVELOPER_KEY_SUCCESSFUL,
    payload,
  }),

  ACTIVATE_DEVELOPER_KEY_FAILED: 'ACTIVATE_DEVELOPER_KEY_FAILED',
  activateDeveloperKeyFailed: (error: unknown) => ({
    type: actions.ACTIVATE_DEVELOPER_KEY_FAILED,
    error: true,
    payload: error,
  }),

  CREATE_OR_EDIT_DEVELOPER_KEY_START: 'CREATE_OR_EDIT_DEVELOPER_KEY_START',
  createOrEditDeveloperKeyStart: () => ({type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_START}),

  CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL: 'CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL',
  createOrEditDeveloperKeySuccessful: () => ({
    type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL,
  }),

  CREATE_OR_EDIT_DEVELOPER_KEY_FAILED: 'CREATE_OR_EDIT_DEVELOPER_KEY_FAILED',
  createOrEditDeveloperKeyFailed: () => ({type: actions.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED}),

  SET_EDITING_DEVELOPER_KEY: 'SET_EDITING_DEVELOPER_KEY',
  setEditingDeveloperKey: (payload: DeveloperKey) => ({
    type: actions.SET_EDITING_DEVELOPER_KEY,
    payload,
  }),

  editDeveloperKey:
    (payload?: DeveloperKey): AnyAction =>
    dispatch => {
      if (payload) {
        dispatch(actions.listDeveloperKeyScopesSet(payload.scopes))
      }
      dispatch(actions.setEditingDeveloperKey(payload))
    },

  DEVELOPER_KEYS_MODAL_OPEN: 'DEVELOPER_KEYS_MODAL_OPEN',
  developerKeysModalOpen: (type: 'api' | 'lti') => {
    window.location.hash = `${type}_key_modal_opened`
    return {type: actions.DEVELOPER_KEYS_MODAL_OPEN}
  },

  DEVELOPER_KEYS_MODAL_CLOSE: 'DEVELOPER_KEYS_MODAL_CLOSE',
  developerKeysModalClose: () => {
    window.location.hash = ''
    return {type: actions.DEVELOPER_KEYS_MODAL_CLOSE}
  },

  SET_BINDING_WORKFLOW_STATE_START: 'SET_BINDING_WORKFLOW_STATE_START',
  setBindingWorkflowStateStart: () => ({type: actions.SET_BINDING_WORKFLOW_STATE_START}),

  SET_BINDING_WORKFLOW_STATE_SUCCESSFUL: 'SET_BINDING_WORKFLOW_STATE_SUCCESSFUL',
  setBindingWorkflowStateSuccessful: response => ({
    type: actions.SET_BINDING_WORKFLOW_STATE_SUCCESSFUL,
    payload: response,
  }),

  SET_BINDING_WORKFLOW_STATE_FAILED: 'SET_BINDING_WORKFLOW_STATE_FAILED',
  setBindingWorkflowStateFailed: (payload: {
    developerKeyId: string
    previousAccountBinding: DeveloperKeyAccountBinding
  }) => ({
    type: actions.SET_BINDING_WORKFLOW_STATE_FAILED,
    payload,
  }),

  LIST_DEVELOPER_KEY_SCOPES_FAILED: 'LIST_DEVELOPER_KEY_SCOPES_FAILED',
  listDeveloperKeyScopesFailed: () => ({type: actions.LIST_DEVELOPER_KEY_SCOPES_FAILED}),

  LIST_DEVELOPER_KEY_SCOPES_START: 'LIST_DEVELOPER_KEY_SCOPES_START',
  listDeveloperKeyScopesStart: () => ({type: actions.LIST_DEVELOPER_KEY_SCOPES_START}),

  LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL: 'LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL',
  listDeveloperKeyScopesSuccessful: (
    payload: Record<
      string,
      {
        controller: string
        action: string
        verb: string
        path: string
        scope: string
        resource: string
        resource_name: string
      }
    >
  ) => ({
    type: actions.LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL,
    payload,
  }),

  LIST_DEVELOPER_KEY_SCOPES_SET: 'LIST_DEVELOPER_KEY_SCOPES_SET',
  listDeveloperKeyScopesSet: (selectedScopes: Array<LtiScope>) => ({
    type: actions.LIST_DEVELOPER_KEY_SCOPES_SET,
    payload: selectedScopes,
  }),

  listDeveloperKeyScopes: (accountId: string | number) => (dispatch: Function) => {
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
  },

  setBindingWorkflowState:
    (developerKey: DeveloperKey, accountId: string, workflowState: string) => dispatch => {
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
    },

  createOrEditDeveloperKey:
    (formData: unknown, url: string, method: string) => (dispatch: Dispatch) => {
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
    },

  getDeveloperKeys: (url: string, newSearch: boolean) => (dispatch: Function) => {
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
  },

  getRemainingDeveloperKeys:
    (
      url: string,
      developerKeysPassedIn: Array<DeveloperKey>,
      callback: (developerKeys: Array<DeveloperKey>) => void
    ) =>
    (dispatch: Function) => {
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
    },

  getRemainingInheritedDeveloperKeys:
    (
      url: string,
      developerKeysPassedIn: Array<DeveloperKey>,
      callback: (developerKeys: Array<DeveloperKey>) => void
    ) =>
    (dispatch: Function) => {
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
    },

  deactivateDeveloperKey: (developerKey: DeveloperKey) => (dispatch: Function) => {
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
  },

  activateDeveloperKey: (developerKey: DeveloperKey) => (dispatch: Function) => {
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
  },

  makeInvisibleDeveloperKey: (developerKey: DeveloperKey) => (dispatch: Function) => {
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
  },

  makeVisibleDeveloperKey: (developerKey: DeveloperKey) => (dispatch: Function) => {
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
  },

  deleteDeveloperKey: (developerKey: DeveloperKey) => (dispatch: Function) => {
    dispatch(actions.deleteDeveloperKeyStart())

    const url = `/api/v1/developer_keys/${developerKey.id}`
    return axios
      .delete(url)
      .then(response => {
        dispatch(actions.listDeveloperKeysDelete(response.data))
        dispatch(actions.deleteDeveloperKeySuccessful())
      })
      .catch(err => dispatch(actions.deleteDeveloperKeyFailed(err)))
  },

  LTI_KEYS_SET_LTI_KEY: 'LTI_KEYS_SET_LTI_KEY',
  ltiKeysSetLtiKey: (payload: boolean) => ({
    type: actions.LTI_KEYS_SET_LTI_KEY,
    payload,
  }),

  RESET_LTI_STATE: 'RESET_LTI_STATE',
  resetLtiState: () => ({type: actions.RESET_LTI_STATE}),

  saveLtiToolConfiguration:
    ({
      account_id,
      settings,
      settings_url,
      developer_key,
    }: {
      account_id: string
      settings?: unknown
      settings_url?: string
      developer_key: DeveloperKey
    }) =>
    (dispatch: Dispatch<AnyAction>) => {
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
          return response.data as LtiDeveloperKeyApiResponse
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
    },

  updateLtiKey: (
    developerKey: DeveloperKey,
    disabled_placements: Array<string>,
    developerKeyId: string,
    toolConfiguration: unknown,
    customFields: unknown
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
        return data.data as LtiDeveloperKeyApiResponse
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
  },
} as const

const inherited = 'inherited=true'

function retrieveDevKeys({
  url,
  dispatch,
  success,
  failure,
}: {
  url: string
  dispatch: Function
  success: (payload: {next: string; developerKeys: Array<DeveloperKey>}) => unknown
  failure: Function
}) {
  axios
    .get(url)
    .then(response => {
      const {next} = parseLinkHeader(response.headers.link)
      const payload = {next, developerKeys: response.data}
      dispatch(success(payload))
    })
    .catch(err => dispatch(failure(err)))
}
function retrieveRemainingDevKeys({
  url,
  developerKeysPassedIn,
  dispatch,
  retrieve,
  success,
  failure,
  callback,
}: {
  url: string
  developerKeysPassedIn: Array<DeveloperKey>
  dispatch: Function
  retrieve: Function
  success: (payload: {next: string; developerKeys: Array<DeveloperKey>}) => unknown
  failure: Function
  callback: (payload: Array<DeveloperKey>) => void
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

export default actions
