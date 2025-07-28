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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const userJSON = {
  id: 17,
  name: 'Deleted User',
  sis_user_id: null,
}

let account_id = null
let user_id = null
let userRestore = null

const server = setupServer()

describe('UserRestore', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    account_id = null
    $('#fixtures').empty()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    account_id = 4
    user_id = 17
    userRestore = new UserRestoreModel({account_id})
    $('#fixtures').append($('<div id="flash_screenreader_holder" />'))
  })

  // Describes searching for a user by ID
  test("triggers 'searching' when search is called", function () {
    const callback = jest.fn()
    userRestore.on('searching', callback)
    userRestore.search(account_id)
    expect(callback).toHaveBeenCalled()
  })

  test('populates UserRestore model with response, keeping its original account_id', async function () {
    server.use(http.get('*/accounts/*/users/*', () => HttpResponse.json(userJSON)))

    userRestore.search(user_id)
    await new Promise(resolve => setTimeout(resolve, 0)) // Wait for async response

    expect(userRestore.get('account_id')).toBe(account_id)
    expect(userRestore.get('id')).toBe(userJSON.id)
  })

  test('set status when user not found', async function () {
    server.use(http.get('*/accounts/*/users/*', () => HttpResponse.json({}, {status: 404})))

    userRestore.search('a')
    await new Promise(resolve => setTimeout(resolve, 0)) // Wait for async response

    expect(userRestore.get('status')).toBe(404)
  })

  test('includes deleted users in search', function () {
    userRestore.search(user_id)
    expect(userRestore.searchUrl()).toMatch(/\?include_deleted_users=true/)
  })

  test('responds with a deferred object', function () {
    const dfd = userRestore.restore()
    expect($.isFunction(dfd.done)).toBeTruthy()
  })

  test('restores a user after search finds a deleted user', async function () {
    server.use(
      http.get('*/accounts/*/users/*', () => HttpResponse.json(userJSON)),
      http.put('*/api/v1/accounts/*/users/*/restore', () =>
        HttpResponse.json({...userJSON, login_id: 'du'}),
      ),
    )

    userRestore.search(user_id)
    await new Promise(resolve => setTimeout(resolve, 0)) // Wait for search

    const dfd = userRestore.restore()
    await dfd // Wait for restore to complete

    expect(dfd.state()).toBe('resolved')
    expect(userRestore.get('login_id')).toBe('du')
  })
})
