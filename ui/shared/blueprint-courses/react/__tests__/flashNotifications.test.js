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

import actions from '../actions'
import FlashNotifications from '../flashNotifications'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

const createMockStore = state => ({
  subs: [],
  subscribe(cb) {
    this.subs.push(cb)
  },
  getState: () => state,
  dispatch: jest.fn(),
  mockStateChange() {
    this.subs.forEach(sub => sub())
  },
})

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
  destroyContainer: jest.fn(),
}))

describe('Blueprint Course FlashNotifications', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  test('subscribes to a store and calls showFlashAlert for each notification in state', done => {
    const flashAlertSpy = FlashAlert.showFlashAlert
    const mockStore = createMockStore({
      notifications: [
        {id: '1', message: 'hello'},
        {id: '2', message: 'world'},
      ],
    })

    FlashNotifications.subscribe(mockStore)
    mockStore.mockStateChange()

    setTimeout(() => {
      expect(flashAlertSpy).toHaveBeenCalledTimes(2)
      expect(flashAlertSpy).toHaveBeenCalledWith({id: '1', message: 'hello'})
      expect(flashAlertSpy).toHaveBeenCalledWith({id: '2', message: 'world'})
      done()
    }, 1)
  })

  test('subscribes to a store and dispatches clearNotifications for each notification in state', done => {
    const mockStore = createMockStore({
      notifications: [
        {id: '1', message: 'hello'},
        {id: '2', message: 'world'},
      ],
    })
    const dispatchSpy = mockStore.dispatch

    FlashNotifications.subscribe(mockStore)
    mockStore.mockStateChange()

    setTimeout(() => {
      expect(dispatchSpy).toHaveBeenCalledTimes(2)
      expect(dispatchSpy).toHaveBeenCalledWith(actions.clearNotification('1'))
      expect(dispatchSpy).toHaveBeenCalledWith(actions.clearNotification('2'))
      done()
    }, 1)
  })
})
