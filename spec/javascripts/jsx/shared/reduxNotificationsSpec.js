/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import { subscribeFlashNotifications, notificationActions, reduceNotifications } from 'jsx/shared/reduxNotifications'
import * as FlashAlert from 'jsx/shared/FlashAlert'

const createMockStore = state => ({
  subs: [],
  subscribe (cb) { this.subs.push(cb) },
  getState: () => state,
  dispatch: () => {},
  mockStateChange () { this.subs.forEach(sub => sub()) },
})

QUnit.module('Redux Notifications')

QUnit.module('subscribeFlashNotifications', {
  teardown () {
    FlashAlert.destroyContainer()
  }
})

test('subscribes to a store and calls showFlashAlert for each notification in state', (assert) => {
  const done = assert.async()
  const flashAlertSpy = sinon.spy(FlashAlert, 'showFlashAlert')
  const mockStore = createMockStore({
    notifications: [{ id: '1', message: 'hello' }, { id: '2', message: 'world' }]
  })

  subscribeFlashNotifications(mockStore)
  mockStore.mockStateChange()

  setTimeout(() => {
    equal(flashAlertSpy.callCount, 2)
    deepEqual(flashAlertSpy.firstCall.args, [{ id: '1', message: 'hello' }])
    deepEqual(flashAlertSpy.secondCall.args, [{ id: '2', message: 'world' }])
    flashAlertSpy.restore()
    done()
  }, 1)
})

test('subscribes to a store and dispatches clearNotifications for each notification in state', (assert) => {
  const done = assert.async()
  const mockStore = createMockStore({
    notifications: [{ id: '1', message: 'hello' }, { id: '2', message: 'world' }]
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')

  subscribeFlashNotifications(mockStore)
  mockStore.mockStateChange()

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.firstCall.args, [notificationActions.clearNotification('1')])
    deepEqual(dispatchSpy.secondCall.args, [notificationActions.clearNotification('2')])
    dispatchSpy.restore()
    done()
  }, 1)
})

QUnit.module('notificationActions')

test('notifyInfo creates action NOTIFY_INFO with type "info" and payload', () => {
  const action = notificationActions.notifyInfo({ message: 'test' })
  deepEqual(action, { type: 'NOTIFY_INFO', payload: { type: 'info', message: 'test' } })
})

test('notifyError creates action NOTIFY_ERROR with type "error" and payload', () => {
  const action = notificationActions.notifyError({ message: 'test' })
  deepEqual(action, { type: 'NOTIFY_ERROR', payload: { type: 'error', message: 'test' } })
})

test('clearNotification creates action CLEAR_NOTIFICATION', () => {
  const action = notificationActions.clearNotification()
  deepEqual(action, { type: 'CLEAR_NOTIFICATION' })
})

QUnit.module('reduceNotifications')

test('catches any action with err and message and treats it as an error notification', () => {
  const action = { type: '_NOT_A_REAL_ACTION_', payload: { message: 'hello world', err: 'bad things happened' } }
  const newState = reduceNotifications([], action)
  equal(newState.length, 1)
  equal(newState[0].type, 'error')
  equal(newState[0].message, 'hello world')
  equal(newState[0].err, 'bad things happened')
})

test('adds new info notification on NOTIFY_INFO', () => {
  const newState = reduceNotifications([], notificationActions.notifyInfo({ message: 'hello world' }))
  equal(newState.length, 1)
  equal(newState[0].type, 'info')
  equal(newState[0].message, 'hello world')
})

test('adds new error notification on NOTIFY_ERROR', () => {
  const newState = reduceNotifications([], notificationActions.notifyError({ message: 'hello world', err: 'bad things happened' }))
  equal(newState.length, 1)
  equal(newState[0].type, 'error')
  equal(newState[0].message, 'hello world')
  equal(newState[0].err, 'bad things happened')
})

test('removes notification on CLEAR_NOTIFICATION', () => {
  const newState = reduceNotifications([
    { id: '1', message: 'hello world', type: 'info' }
  ], notificationActions.clearNotification('1'))
  equal(newState.length, 0)
})
