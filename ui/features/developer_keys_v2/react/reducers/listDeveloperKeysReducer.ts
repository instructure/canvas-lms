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

import ACTION_NAMES from '../actions/developerKeysActions'
import type {DeveloperKey} from '../../model/api/DeveloperKey'
import _ from 'lodash'
import {makeReducer} from './makeReducer'

export interface ListDeveloperKeysState {
  listDeveloperKeysPending: boolean
  listDeveloperKeysSuccessful: boolean
  listDeveloperKeysError: unknown
  listInheritedDeveloperKeysPending: boolean
  listInheritedDeveloperKeysSuccessful: boolean
  listInheritedDeveloperKeysError: unknown
  list: Array<DeveloperKey>
  inheritedList: Array<DeveloperKey>
  nextPage: string | null | undefined
  inheritedNextPage: string | null | undefined
}

const initialState: ListDeveloperKeysState = {
  listDeveloperKeysPending: false,
  listDeveloperKeysSuccessful: false,
  listDeveloperKeysError: null,
  listInheritedDeveloperKeysPending: false,
  listInheritedDeveloperKeysSuccessful: false,
  listInheritedDeveloperKeysError: null,
  list: [],
  inheritedList: [],
  nextPage: null,
  inheritedNextPage: null,
}

export default makeReducer(initialState, {
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_START]: (state, action) => ({
    ...state,
    list: action.payload ? [] : state.list,
    listDeveloperKeysPending: true,
    listDeveloperKeysSuccessful: false,
    listDeveloperKeysError: null,
  }),
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_SUCCESSFUL]: (state, action) => {
    return {
      ...state,
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: true,
      list: action.payload.developerKeys,
      nextPage: action.payload.next,
    }
  },
  [ACTION_NAMES.LIST_REMAINING_DEVELOPER_KEYS_SUCCESSFUL]: (state, action) => {
    const list = state.list.slice()
    list.push(...action.payload.developerKeys)
    return {
      ...state,
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: true,
      list,
      nextPage: action.payload.next,
    }
  },
  [ACTION_NAMES.LIST_INHERITED_DEVELOPER_KEYS_START]: (state, action) => ({
    ...state,
    inheritedList: action.payload ? [] : state.inheritedList,
    listInheritedDeveloperKeysPending: true,
    listInheritedDeveloperKeysSuccessful: false,
    listInheritedDeveloperKeysError: null,
  }),
  [ACTION_NAMES.LIST_INHERITED_DEVELOPER_KEYS_SUCCESSFUL]: (state, action) => {
    return {
      ...state,
      listInheritedDeveloperKeysPending: false,
      listInheritedDeveloperKeysSuccessful: true,
      inheritedList: action.payload.developerKeys,
      inheritedNextPage: action.payload.next,
    }
  },
  [ACTION_NAMES.LIST_REMAINING_INHERITED_DEVELOPER_KEYS_SUCCESSFUL]: (state, action) => {
    const inheritedList = state.inheritedList.slice()
    inheritedList.push(...action.payload.developerKeys)
    return {
      ...state,
      listInheritedDeveloperKeysPending: false,
      listInheritedDeveloperKeysSuccessful: true,
      inheritedList,
      inheritedNextPage: action.payload.next,
    }
  },
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_REPLACE]: (state, action) => ({
    ...state,
    list: state.list.map(developerKey =>
      action.payload.id === developerKey.id ? action.payload : developerKey
    ),
  }),
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_REPLACE_BINDING_STATE]: (state, action) => {
    const developerKeyId = action.payload.developerKeyId
    const accountBinding = action.payload.newAccountBinding

    const newList = state.list.map(developerKey => {
      if (developerKey.id !== developerKeyId.toString()) {
        return developerKey
      }
      return {...developerKey, developer_key_account_binding: accountBinding}
    })

    const newInheritedList = state.inheritedList.map(developerKey => {
      if (developerKey.id !== developerKeyId.toString()) {
        return developerKey
      }
      return {...developerKey, developer_key_account_binding: accountBinding}
    })

    return {
      ...state,
      list: newList,
      inheritedList: newInheritedList,
    }
  },
  [ACTION_NAMES.SET_BINDING_WORKFLOW_STATE_SUCCESSFUL]: (state, action) => {
    const newList = state.list.map(developerKey => {
      if (developerKey.id !== action.payload.developer_key_id.toString()) {
        return developerKey
      }
      return {...developerKey, developer_key_account_binding: action.payload}
    })

    const newInheritedList = state.inheritedList.map(developerKey => {
      if (developerKey.id !== action.payload.developer_key_id.toString()) {
        return developerKey
      }
      return {...developerKey, developer_key_account_binding: action.payload}
    })

    return {
      ...state,
      list: newList,
      inheritedList: newInheritedList,
    }
  },
  [ACTION_NAMES.SET_BINDING_WORKFLOW_STATE_FAILED]: (state, action) => {
    // This is the same code as the function above it. Will DRY this up
    // in a separate commit to keep this one more coherent.
    const developerKeyId = action.payload.developerKeyId
    const previousAccountBinding = action.payload.previousAccountBinding

    const newList = state.list.map(developerKey => {
      if (developerKey.id !== developerKeyId.toString()) {
        return developerKey
      }
      if (Object.keys(previousAccountBinding).length === 0) {
        return _.omit(developerKey, 'developer_key_account_binding')
      }
      return {...developerKey, developer_key_account_binding: previousAccountBinding}
    })

    const newInheritedList = state.inheritedList.map(developerKey => {
      if (developerKey.id !== developerKeyId.toString()) {
        return developerKey
      }
      if (Object.keys(previousAccountBinding).length === 0) {
        return _.omit(developerKey, 'developer_key_account_binding')
      }
      return {...developerKey, developer_key_account_binding: previousAccountBinding}
    })

    return {
      ...state,
      list: newList,
      inheritedList: newInheritedList,
    }
  },
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_DELETE]: (state, action) => ({
    ...state,
    list: state.list.filter(
      developerKey => action.payload.id.toString() !== developerKey.id.toString()
    ),
  }),
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_PREPEND]: (state, action) => {
    const list = state.list.slice()
    list.unshift(action.payload)
    return {
      ...state,
      list,
    }
  },
  [ACTION_NAMES.LIST_DEVELOPER_KEYS_FAILED]: (state, action) => ({
    ...state,
    listDeveloperKeysPending: false,
    listDeveloperKeysError: action.payload,
  }),
  [ACTION_NAMES.LIST_INHERITED_DEVELOPER_KEYS_FAILED]: (state, action) => ({
    ...state,
    listInheritedDeveloperKeysPending: false,
    listInheritedDeveloperKeysError: action.payload,
  }),
})
