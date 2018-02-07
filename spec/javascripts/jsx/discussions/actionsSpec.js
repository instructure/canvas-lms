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

import actions from 'jsx/discussions/actions'
import * as apiClient from 'jsx/discussions/apiClient'
import $ from 'jquery';
import 'compiled/jquery.rails_flash_notifications'

let sandbox = null

const mockApiClient = (method, res) => {
  sandbox = sinon.sandbox.create()
  sandbox.stub(apiClient, method).returns(res)
}

const mockSuccess = (method, data = {}) => mockApiClient(method, Promise.resolve(data))
const mockFail = (method, err = new Error('Request Failed')) => mockApiClient(method, Promise.reject(err))

QUnit.module('Discussions redux actions', {
  teardown () {
    if (sandbox) sandbox.restore()
    sandbox = null
  }
})

test('togglePin dispatches TOGGLE_PIN_START if we try to pin discussion', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: false, locked: false }
  const dispatchSpy = sinon.spy()
  actions.togglePin({pinnedState: true, discussion, closedState: false})(dispatchSpy, () => state)
  const expected = [
    {
      "payload": {
        "closedState": false,
        "discussion": {
          "locked": false,
          "pinned": true
        },
        "pinnedState": true
      },
      "type": "TOGGLE_PIN_START"
    }
  ]
  deepEqual(dispatchSpy.firstCall.args, expected)
})

test('togglePin will not dispatch TOGGLE_PIN_START if pinned and we pin it again', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false }
  const dispatchSpy = sinon.spy()
  actions.togglePin({pinnedState: true, discussion, closedState: false})(dispatchSpy, () => state)
  equal(dispatchSpy.callCount, 0)
})

test('closeForComments dispatches CLOSE_FOR_COMMENTS_START if we lock discussion', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const dispatchSpy = sinon.spy()
  actions.closeForComments({pinnedState: true, discussion, closedState: true})(dispatchSpy, () => state)
  const expected = [
    {
      "payload": {
        "closedState": true,
        "discussion": {
          "locked": true,
          "pinned": true
        },
        "pinnedState": true
      },
      "type": "CLOSE_FOR_COMMENTS_START"
    }
  ]
  deepEqual(dispatchSpy.firstCall.args, expected)
})

test('closeForComments will not dispatch CLOSE_FOR_COMMENTS_START if discussion is already locked', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: true}
  const dispatchSpy = sinon.spy()
  actions.closeForComments({pinnedState: true, discussion, closedState: true})(dispatchSpy, () => state)
  equal(dispatchSpy.callCount, 0)
})

test('togglePin calls apiClient.updateDiscussion with passed in discussion when pinning discussion', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: true}
  const dispatchSpy = sinon.spy()
  mockSuccess('updateDiscussion', { successes: [], failures: [] })
  actions.togglePin({pinnedState:false, discussion, closedState: true})(dispatchSpy, () => state)
  deepEqual(apiClient.updateDiscussion.firstCall.args[1], discussion)
})

test('closeForComments calls apiClient.updateDiscussion with passed in discussion when locking discussion', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const dispatchSpy = sinon.spy()
  mockSuccess('updateDiscussion', { successes: [], failures: [] })
  actions.closeForComments({pinnedState:true, discussion, closedState: true})(dispatchSpy, () => state)
  deepEqual(apiClient.updateDiscussion.firstCall.args[1], discussion)
})

test('togglePin dispatches TOGGLE_PIN_FAIL if promise fails', (assert) => {
  const done = assert.async()
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const dispatchSpy = sinon.spy()

  mockFail('updateDiscussion', { err: 'something bad happened' })
  actions.togglePin({pinnedState:true, discussion, closedState: true})(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'TOGGLE_PIN_FAIL')
    done()
  })
})

test('closeForComments dispatches CLOSE_FOR_COMMENTS_FAIL if promise fails', (assert) => {
  const done = assert.async()
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const dispatchSpy = sinon.spy()

  mockFail('updateDiscussion', { err: 'something bad happened' })
  actions.closeForComments({pinnedState:true, discussion, closedState: true})(dispatchSpy, () => state)

  setTimeout(() => {
    equal(dispatchSpy.secondCall.args[0].type, 'CLOSE_FOR_COMMENTS_FAIL')
    done()
  })
})

