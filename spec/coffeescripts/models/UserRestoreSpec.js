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

import UserRestoreModel from 'ui/features/account_admin_tools/backbone/models/UserRestore'
import $ from 'jquery'
import 'jquery-migrate'

const userJSON = {
  id: 17,
  name: 'Deleted User',
  sis_user_id: null,
}

QUnit.module('UserRestore', {
  setup() {
    this.account_id = 4
    this.user_id = 17
    this.userRestore = new UserRestoreModel({account_id: this.account_id})
    this.server = sinon.fakeServer.create()
    this.clock = sinon.useFakeTimers()
    return $('#fixtures').append($('<div id="flash_screenreader_holder" />'))
  },
  teardown() {
    this.server.restore()
    this.clock.restore()
    this.account_id = null
    $('#fixtures').empty()
  },
})

// Describes searching for a user by ID
test("triggers 'searching' when search is called", function () {
  const callback = sinon.spy()
  this.userRestore.on('searching', callback)
  this.userRestore.search(this.account_id)
  ok(callback.called, 'Searching event is called when searching')
})

test('populates UserRestore model with response, keeping its original account_id', function () {
  this.userRestore.search(this.user_id)
  this.server.respond('GET', this.userRestore.searchUrl(), [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(userJSON),
  ])
  equal(this.userRestore.get('account_id'), this.account_id, 'account id stayed the same')
  equal(this.userRestore.get('id'), userJSON.id, 'user id was updated')
})

test('set status when user not found', function () {
  this.userRestore.search('a')
  this.server.respond('GET', this.userRestore.searchUrl(), [
    404,
    {'Content-Type': 'application/json'},
    JSON.stringify({}),
  ])
  equal(this.userRestore.get('status'), 404)
})

test('responds with a deferred object', function () {
  const dfd = this.userRestore.restore()
  ok($.isFunction(dfd.done, 'This is a deferred object'))
})

test('restores a user after search finds a deleted user', function () {
  this.userRestore.search(this.user_id)
  this.server.respond('GET', this.userRestore.searchUrl(), [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(userJSON),
  ])
  const dfd = this.userRestore.restore()
  this.server.respond('PUT', `/api/v1/accounts/4/users/17/restore`, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify({...userJSON, login_id: 'du'}),
  ])
  // eslint-disable-next-line qunit/no-ok-equality
  ok(dfd.state() === 'resolved', 'All ajax request in this deferred object should be resolved')
  equal(this.userRestore.get('login_id'), 'du')
})
