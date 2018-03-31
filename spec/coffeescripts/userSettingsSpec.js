/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import userSettings from 'compiled/userSettings'

const globalObj = window

QUnit.module('UserSettings', {
  setup() {
    this._ENV = globalObj.ENV
    globalObj.ENV = {
      current_user_id: 1,
      context_asset_string: 'course_1'
    }
    userSettings.globalEnv = globalObj.ENV
  },
  teardown() {
    globalObj.ENV = this._ENV
  }
})

test('`get` should return what was `set`', () => {
  userSettings.set('foo', 'bar')
  equal(userSettings.get('foo'), 'bar')
})

test('it should strigify/parse JSON', () => {
  const testObject = {
    foo: [1, 2, 3],
    bar: 'true',
    baz: true
  }
  userSettings.set('foo', testObject)
  deepEqual(userSettings.get('foo'), testObject)
})

test('it should store different things for different users', () => {
  userSettings.set('foo', 1)
  globalObj.ENV.current_user_id = 2
  userSettings.set('foo', 2)
  equal(userSettings.get('foo'), 2)
  globalObj.ENV.current_user_id = 1
  equal(userSettings.get('foo'), 1)
})

test('it should store different things for different contexts', () => {
  userSettings.contextSet('foo', 1)
  globalObj.ENV.context_asset_string = 'course_2'
  userSettings.contextSet('foo', 2)
  equal(userSettings.contextGet('foo'), 2)
  globalObj.ENV.context_asset_string = 'course_1'
  equal(userSettings.contextGet('foo'), 1)
})
