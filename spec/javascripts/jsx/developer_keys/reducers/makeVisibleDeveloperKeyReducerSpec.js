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
import reducer from 'jsx/developer_keys/reducers/makeVisibleDeveloperKeyReducer'

QUnit.module('makeVisibleDeveloperKeyReducer');

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(defaults.makeVisibleDeveloperKeyPending, false);
  equal(defaults.makeVisibleDeveloperKeySuccessful, false);
  equal(defaults.makeVisibleDeveloperKeyError, null);
});

test('responds to makeVisibleDeveloperKeyStart', () => {
  const state = {
    makeVisibleDeveloperKeyPending: false,
    makeVisibleDeveloperKeySuccessful: true,
    makeVisibleDeveloperKeyError: {}
  };

  const action = actions.makeVisibleDeveloperKeyStart();
  const newState = reducer(state, action);
  equal(newState.makeVisibleDeveloperKeyPending, true);
  equal(newState.makeVisibleDeveloperKeySuccessful, false);
  equal(newState.makeVisibleDeveloperKeyError, null);
});

test('responds to makeVisibleDeveloperKeySuccessful', () => {
  const state = {
    makeVisibleDeveloperKeyPending: true,
    makeVisibleDeveloperKeySuccessful: false,
  };
  const payload = {};
  const action = actions.makeVisibleDeveloperKeySuccessful(payload);
  const newState = reducer(state, action);
  equal(newState.makeVisibleDeveloperKeyPending, false);
  equal(newState.makeVisibleDeveloperKeySuccessful, true);
});

test('responds to makeVisibleDeveloperKeyFailed', () => {
  const state = {
    makeVisibleDeveloperKeyPending: true,
    makeVisibleDeveloperKeyError: null
  };
  const error = {};

  const action = actions.makeVisibleDeveloperKeyFailed(error);
  const newState = reducer(state, action);
  equal(newState.makeVisibleDeveloperKeyPending, false);
  equal(newState.makeVisibleDeveloperKeyError, error);
});


