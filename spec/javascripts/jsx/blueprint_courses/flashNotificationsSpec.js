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

import actions from '@canvas/blueprint-courses/react/actions'
import FlashNotifications from '@canvas/blueprint-courses/react/flashNotifications'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

const createMockStore = state => ({
  subs: [],
  subscribe(cb) {
    this.subs.push(cb)
  },
  getState: () => state,
  dispatch: () => {},
  mockStateChange() {
    this.subs.forEach(sub => sub())
  },
})

QUnit.module('Blueprint Course FlashNotifications', {
  teardown() {
    FlashAlert.destroyContainer()
  },
})

test('subscribes to a store and calls showFlashAlert for each notification in state', assert => {
  const done = assert.async()
  const flashAlertSpy = sinon.spy(FlashAlert, 'showFlashAlert')
  const mockStore = createMockStore({
    notifications: [
      {id: '1', message: 'hello'},
      {id: '2', message: 'world'},
    ],
  })

  FlashNotifications.subscribe(mockStore)
  mockStore.mockStateChange()

  setTimeout(() => {
    equal(flashAlertSpy.callCount, 2)
    deepEqual(flashAlertSpy.firstCall.args, [{id: '1', message: 'hello'}])
    deepEqual(flashAlertSpy.secondCall.args, [{id: '2', message: 'world'}])
    flashAlertSpy.restore()
    done()
  }, 1)
})

test('subscribes to a store and dispatches clearNotifications for each notification in state', assert => {
  const done = assert.async()
  const mockStore = createMockStore({
    notifications: [
      {id: '1', message: 'hello'},
      {id: '2', message: 'world'},
    ],
  })
  const dispatchSpy = sinon.spy(mockStore, 'dispatch')

  FlashNotifications.subscribe(mockStore)
  mockStore.mockStateChange()

  setTimeout(() => {
    equal(dispatchSpy.callCount, 2)
    deepEqual(dispatchSpy.firstCall.args, [actions.clearNotification('1')])
    deepEqual(dispatchSpy.secondCall.args, [actions.clearNotification('2')])
    dispatchSpy.restore()
    done()
  }, 1)
})
