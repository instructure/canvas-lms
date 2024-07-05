/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import UserRestoreModel from '../UserRestore'
import $ from 'jquery'
import 'jquery-migrate'
import sinon from 'sinon'

const userJSON = {
  id: 17,
  name: 'Deleted User',
  sis_user_id: null,
}

let account_id = null
let user_id = null
let userRestore = null
let server = null
let clock = null

describe('UserRestore', () => {
  beforeEach(() => {
    account_id = 4
    user_id = 17
    userRestore = new UserRestoreModel({account_id})
    server = sinon.fakeServer.create()
    clock = sinon.useFakeTimers()
    return $('#fixtures').append($('<div id="flash_screenreader_holder" />'))
  })
  afterEach(() => {
    server.restore()
    clock.restore()
    account_id = null
    $('#fixtures').empty()
  })

  // Describes searching for a user by ID
  test("triggers 'searching' when search is called", function () {
    const callback = sinon.spy()
    userRestore.on('searching', callback)
    userRestore.search(account_id)
    expect(callback.called).toBeTruthy()
  })

  test('populates UserRestore model with response, keeping its original account_id', function () {
    userRestore.search(user_id)
    server.respond('GET', userRestore.searchUrl(), [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(userJSON),
    ])
    expect(userRestore.get('account_id')).toBe(account_id)
    expect(userRestore.get('id')).toBe(userJSON.id)
  })

  test('set status when user not found', function () {
    userRestore.search('a')
    server.respond('GET', userRestore.searchUrl(), [
      404,
      {'Content-Type': 'application/json'},
      JSON.stringify({}),
    ])

    expect(userRestore.get('status')).toBe(404)
  })

  test('responds with a deferred object', function () {
    const dfd = userRestore.restore()
    expect($.isFunction(dfd.done)).toBeTruthy()
  })

  test('restores a user after search finds a deleted user', function () {
    userRestore.search(user_id)
    server.respond('GET', userRestore.searchUrl(), [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(userJSON),
    ])
    const dfd = userRestore.restore()
    server.respond('PUT', `/api/v1/accounts/4/users/17/restore`, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify({...userJSON, login_id: 'du'}),
    ])
    expect(dfd.state() === 'resolved').toBeTruthy()
    expect(userRestore.get('login_id')).toBe('du')
  })
})
