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

import actions from 'jsx/developer_keys/actions/developerKeysActions'
import reducer from 'jsx/developer_keys/reducers/listDeveloperKeysReducer'

QUnit.module('listDeveloperKeysReducer');

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(Array.isArray(defaults.list), true);
  equal(defaults.list.length, 0);
  equal(defaults.listDeveloperKeysPending, false);
  equal(defaults.listDeveloperKeysSuccessful, false);
  equal(defaults.listDeveloperKeysError, null);
});

test('responds to listDeveloperKeysStart', () => {
  const state = {
    listDeveloperKeysPending: false,
    listDeveloperKeysSuccessful: true,
    listDeveloperKeysError: {}
  };

  const action = actions.listDeveloperKeysStart();
  const newState = reducer(state, action);
  equal(newState.listDeveloperKeysPending, true);
  equal(newState.listDeveloperKeysSuccessful, false);
  equal(newState.listDeveloperKeysError, null);
});

test('responds to listInheritedDeveloperKeysStart', () => {
  const state = {
    listInheritedDeveloperKeysPending: false,
    listInheritedDeveloperKeysSuccessful: true,
    listInheritedDeveloperKeysError: {}
  };

  const action = actions.listInheritedDeveloperKeysStart();
  const newState = reducer(state, action);
  equal(newState.listInheritedDeveloperKeysPending, true);
  equal(newState.listInheritedDeveloperKeysSuccessful, false);
  equal(newState.listInheritedDeveloperKeysError, null);
});

test('responds to listDeveloperKeysSuccessful', () => {
  const state = {
    listDeveloperKeysPending: true,
    listDeveloperKeysSuccessful: false,
    list: []
  };
  const payload = {developerKeys: []};
  const action = actions.listDeveloperKeysSuccessful(payload);
  const newState = reducer(state, action);
  equal(newState.listDeveloperKeysPending, false);
  equal(newState.listDeveloperKeysSuccessful, true);
  equal(newState.list.length, payload.developerKeys.length);
});

test('responds to listDeveloperKeysSuccessful', () => {
  const state = {
    listInheritedDeveloperKeysPending: true,
    listInheritedDeveloperKeysSuccessful: false,
    inheritedList: []
  };
  const payload = {developerKeys: [{id: 1}]};
  const action = actions.listInheritedDeveloperKeysSuccessful(payload);
  const newState = reducer(state, action);
  equal(newState.listInheritedDeveloperKeysPending, false);
  equal(newState.listInheritedDeveloperKeysSuccessful, true);
  equal(newState.inheritedList.length, payload.developerKeys.length);
});

test('responds to listDeveloperKeysFailed', () => {
  const state = {
    listDeveloperKeysPending: true,
    listDeveloperKeysError: null
  };
  const error = {};

  const action = actions.listDeveloperKeysFailed(error);
  const newState = reducer(state, action);
  equal(newState.listDeveloperKeysPending, false);
  equal(newState.listDeveloperKeysError, error);
});

test('responds to listInheritedDeveloperKeysFailed', () => {
  const state = {
    listInheritedDeveloperKeysPending: true,
    listInheritedDeveloperKeysError: null
  };
  const error = {};

  const action = actions.listInheritedDeveloperKeysFailed(error);
  const newState = reducer(state, action);
  equal(newState.listInheritedDeveloperKeysPending, false);
  equal(newState.listInheritedDeveloperKeysError, error);
});

test('responds to listDeveloperKeysReplace', () => {
  const state = {
    list: [
      {id: 11, name: 'a'},
      {id: 22, name: 'b'},
      {id: 33, name: 'c'},
    ]
  };

  const payload = {id: 22, name: 'zz'};
  const action = actions.listDeveloperKeysReplace(payload);
  const newState = reducer(state, action);

  propEqual(newState.list, [{id: 11, name: 'a'},
                            {id: 22, name: 'zz'},
                            {id: 33, name: 'c'}])
});

test('istDeveloperKeysReplaceBindingState replaces state in list', () => {
  const state = {
    list: [
      {id: '11', name: 'a'},
    ],
    inheritedList: []
  }

  const payload = {
    developer_key_id: 11,
    workflow_state: 'active',
    account_id: 1
  }

  const action = actions.listDeveloperKeysReplaceBindingState(payload);
  const newState = reducer(state, action);

  propEqual(newState.list[0].developer_key_account_binding.workflow_state, 'active')
});

test('listDeveloperKeysReplaceBindingState in inherited list', () => {
  const state = {
    list: [],
    inheritedList: [
      {id: '11', name: 'a'},
    ]
  }

  const payload = {
    developer_key_id: 11,
    workflow_state: 'active',
    account_id: 1
  }

  const action = actions.listDeveloperKeysReplaceBindingState(payload);
  const newState = reducer(state, action);

  propEqual(newState.inheritedList[0].developer_key_account_binding.workflow_state, 'active')
});

test('responds to listDeveloperKeysDelete', () => {
  const state = {
    list: [
      {id: 44, name: 'dd'},
      {id: 55, name: 'ee'},
      {id: 66, name: 'ff'},
    ]
  };

  const payload = {id: 55};
  const action = actions.listDeveloperKeysDelete(payload);
  const newState = reducer(state, action);

  propEqual(newState.list, [{id: 44, name: 'dd'},
                            {id: 66, name: 'ff'}])
});

test('responds to listDeveloperKeysPrepend', () => {
  const state = {
    list: [
      {id: 77, name: 'AA'},
      {id: 88, name: 'BB'},
    ]
  };

  const payload = {id: 99, name: 'OO'};
  const action = actions.listDeveloperKeysPrepend(payload);
  const newState = reducer(state, action);

  propEqual(newState.list, [{id: 99, name: 'OO'},
                            {id: 77, name: 'AA'},
                            {id: 88, name: 'BB'}])
});

