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

import actions from '../../actions/developerKeysActions'
import reducer from '../listDeveloperKeysReducer'

const defaults = reducer(undefined, {})

it('there are defaults', () => {
  expect(Array.isArray(defaults.list)).toBe(true)
  expect(defaults.list).toHaveLength(0)
  expect(defaults.listDeveloperKeysPending).toBe(false)
  expect(defaults.listDeveloperKeysSuccessful).toBe(false)
  expect(defaults.listDeveloperKeysError).toBeNull()
})

it('responds to listDeveloperKeysStart', () => {
  const state = {
    listDeveloperKeysPending: false,
    listDeveloperKeysSuccessful: true,
    listDeveloperKeysError: {},
  }

  const action = actions.listDeveloperKeysStart()
  const newState = reducer(state, action)
  expect(newState.listDeveloperKeysPending).toBe(true)
  expect(newState.listDeveloperKeysSuccessful).toBe(false)
  expect(newState.listDeveloperKeysError).toBeNull()
})

it('responds to listInheritedDeveloperKeysStart', () => {
  const state = {
    listInheritedDeveloperKeysPending: false,
    listInheritedDeveloperKeysSuccessful: true,
    listInheritedDeveloperKeysError: {},
  }

  const action = actions.listInheritedDeveloperKeysStart()
  const newState = reducer(state, action)
  expect(newState.listInheritedDeveloperKeysPending).toBe(true)
  expect(newState.listInheritedDeveloperKeysSuccessful).toBe(false)
  expect(newState.listInheritedDeveloperKeysError).toBeNull()
})

it('responds to listDeveloperKeysSuccessful', () => {
  const state = {
    listDeveloperKeysPending: true,
    listDeveloperKeysSuccessful: false,
    list: [],
  }
  const payload = {developerKeys: []}
  const action = actions.listDeveloperKeysSuccessful(payload)
  const newState = reducer(state, action)
  expect(newState.listDeveloperKeysPending).toBe(false)
  expect(newState.listDeveloperKeysSuccessful).toBe(true)
  expect(newState.list).toHaveLength(payload.developerKeys.length)
})

it('responds to listRemainingDeveloperKeysSuccessful', () => {
  const state = {
    listDeveloperKeysPending: true,
    listDeveloperKeysSuccessful: false,
    list: [],
  }
  const payload = {developerKeys: []}
  const action = actions.listRemainingDeveloperKeysSuccessful(payload)
  const newState = reducer(state, action)
  expect(newState.listDeveloperKeysPending).toBe(false)
  expect(newState.listDeveloperKeysSuccessful).toBe(true)
  expect(newState.list).toHaveLength(payload.developerKeys.length)
})

it('responds to listInheritedDeveloperKeysSuccessful', () => {
  const state = {
    listInheritedDeveloperKeysPending: true,
    listInheritedDeveloperKeysSuccessful: false,
    inheritedList: [],
  }
  const payload = {developerKeys: [{id: 1}]}
  const action = actions.listInheritedDeveloperKeysSuccessful(payload)
  const newState = reducer(state, action)
  expect(newState.listInheritedDeveloperKeysPending).toBe(false)
  expect(newState.listInheritedDeveloperKeysSuccessful).toBe(true)
  expect(newState.inheritedList).toHaveLength(payload.developerKeys.length)
})

it('responds to listRemainingInheritedDeveloperKeysSuccessful', () => {
  const state = {
    listInheritedDeveloperKeysPending: true,
    listInheritedDeveloperKeysSuccessful: false,
    inheritedList: [],
  }
  const payload = {developerKeys: [{id: 1}]}
  const action = actions.listRemainingInheritedDeveloperKeysSuccessful(payload)
  const newState = reducer(state, action)
  expect(newState.listInheritedDeveloperKeysPending).toBe(false)
  expect(newState.listInheritedDeveloperKeysSuccessful).toBe(true)
  expect(newState.inheritedList).toHaveLength(payload.developerKeys.length)
})

it('responds to listDeveloperKeysFailed', () => {
  const state = {
    listDeveloperKeysPending: true,
    listDeveloperKeysError: null,
  }
  const error = {}

  const action = actions.listDeveloperKeysFailed(error)
  const newState = reducer(state, action)
  expect(newState.listDeveloperKeysPending).toBe(false)
  expect(newState.listDeveloperKeysError).toBe(error)
})

it('responds to listInheritedDeveloperKeysFailed', () => {
  const state = {
    listInheritedDeveloperKeysPending: true,
    listInheritedDeveloperKeysError: null,
  }
  const error = {}

  const action = actions.listInheritedDeveloperKeysFailed(error)
  const newState = reducer(state, action)
  expect(newState.listInheritedDeveloperKeysPending).toBe(false)
  expect(newState.listInheritedDeveloperKeysError).toBe(error)
})

it('responds to listDeveloperKeysReplace', () => {
  const state = {
    list: [
      {id: 11, name: 'a'},
      {id: 22, name: 'b'},
      {id: 33, name: 'c'},
    ],
  }

  const payload = {id: 22, name: 'zz'}
  const action = actions.listDeveloperKeysReplace(payload)
  const newState = reducer(state, action)

  expect(newState.list).toEqual([
    {id: 11, name: 'a'},
    {id: 22, name: 'zz'},
    {id: 33, name: 'c'},
  ])
})

it('listDeveloperKeysReplaceBindingState replaces state in list', () => {
  const state = {
    list: [{id: '11', name: 'a'}],
    inheritedList: [],
  }

  const payload = {
    developer_key_id: 11,
    workflow_state: 'active',
    account_id: 1,
  }

  const action = actions.listDeveloperKeysReplaceBindingState({
    developerKeyId: 11,
    newAccountBinding: payload,
  })
  const newState = reducer(state, action)

  expect(newState.list[0].developer_key_account_binding.workflow_state).toBe('active')
})

it('listDeveloperKeysReplaceBindingState in inherited list', () => {
  const state = {
    list: [],
    inheritedList: [{id: '11', name: 'a'}],
  }

  const payload = {
    developer_key_id: 11,
    workflow_state: 'active',
    account_id: 1,
  }

  const action = actions.listDeveloperKeysReplaceBindingState({
    developerKeyId: 11,
    newAccountBinding: payload,
  })
  const newState = reducer(state, action)

  expect(newState.inheritedList[0].developer_key_account_binding.workflow_state).toBe('active')
})

it('resets key state in SET_BINDING_WORKFLOW_STATE_FAILED', () => {
  const accountBinding = {
    id: '1',
    account_id: '2',
    developer_key_id: '11',
    workflow_state: 'off',
    account_owns_binding: true,
  }
  const previousAccountBinding = Object.assign(accountBinding, {workflow_state: 'on'})

  const state = {
    list: [
      {
        id: '11',
        name: 'a',
        developer_key_account_binding: accountBinding,
      },
    ],
    inheritedList: [],
  }
  const action = actions.setBindingWorkflowStateFailed({
    developerKeyId: 11,
    previousAccountBinding,
  })
  const newState = reducer(state, action)

  expect(newState.list[0].developer_key_account_binding.workflow_state).toBe('on')
})

it('resets key state in SET_BINDING_WORKFLOW_STATE_FAILED if it had no account binding', () => {
  const accountBinding = {
    id: '1',
    account_id: '2',
    developer_key_id: '11',
    workflow_state: 'off',
    account_owns_binding: true,
  }
  const previousAccountBinding = {}

  const state = {
    list: [
      {
        id: '11',
        name: 'a',
        developer_key_account_binding: accountBinding,
      },
    ],
    inheritedList: [],
  }
  const action = actions.setBindingWorkflowStateFailed({
    developerKeyId: 11,
    previousAccountBinding,
  })
  const newState = reducer(state, action)

  expect(newState.list[0].developer_key_account_binding).toBeUndefined()
})

it('responds to listDeveloperKeysDelete', () => {
  const state = {
    list: [
      {id: '44', name: 'dd'},
      {id: '55', name: 'ee'},
      {id: '66', name: 'ff'},
    ],
  }

  const payload = {id: 55}
  const action = actions.listDeveloperKeysDelete(payload)
  const newState = reducer(state, action)

  expect(newState.list).toEqual([
    {id: '44', name: 'dd'},
    {id: '66', name: 'ff'},
  ])
})

it('responds to listDeveloperKeysPrepend', () => {
  const state = {
    list: [
      {id: 77, name: 'AA'},
      {id: 88, name: 'BB'},
    ],
  }

  const payload = {id: 99, name: 'OO'}
  const action = actions.listDeveloperKeysPrepend(payload)
  const newState = reducer(state, action)

  expect(newState.list).toEqual([
    {id: 99, name: 'OO'},
    {id: 77, name: 'AA'},
    {id: 88, name: 'BB'},
  ])
})
