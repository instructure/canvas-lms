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
import reducer from 'jsx/developer_keys/reducers/deleteReducer'

QUnit.module('deleteDeveloperKeyReducer');

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(defaults.deleteDeveloperKeyPending, false);
  equal(defaults.deleteDeveloperKeySuccessful, false);
  equal(defaults.deleteDeveloperKeyError, null);
});

test('responds to deleteDeveloperKeyStart', () => {
  const state = {
    deleteDeveloperKeyPending: false,
    deleteDeveloperKeySuccessful: true,
    deleteDeveloperKeyError: {}
  };

  const action = actions.deleteDeveloperKeyStart();
  const newState = reducer(state, action);
  equal(newState.deleteDeveloperKeyPending, true);
  equal(newState.deleteDeveloperKeySuccessful, false);
  equal(newState.deleteDeveloperKeyError, null);
});

test('responds to deleteDeveloperKeySuccessful', () => {
  const state = {
    deleteDeveloperKeyPending: true,
    deleteDeveloperKeySuccessful: false,
  };
  const payload = {};
  const action = actions.deleteDeveloperKeySuccessful(payload);
  const newState = reducer(state, action);
  equal(newState.deleteDeveloperKeyPending, false);
  equal(newState.deleteDeveloperKeySuccessful, true);
});

test('responds to deleteDeveloperKeyFailed', () => {
  const state = {
    deleteDeveloperKeyPending: true,
    deleteDeveloperKeyError: null
  };
  const error = {};

  const action = actions.deleteDeveloperKeyFailed(error);
  const newState = reducer(state, action);
  equal(newState.deleteDeveloperKeyPending, false);
  equal(newState.deleteDeveloperKeyError, error);
});
