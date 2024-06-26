/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {subscribeFlashNotifications, notificationActions, reduceNotifications} from '../actions'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
  destroyContainer: jest.fn(),
}))

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

describe('Redux Notifications', () => {
  afterEach(() => {
    FlashAlert.destroyContainer.mockClear()
  })

  test('subscribes to a store and calls showFlashAlert for each notification in state', done => {
    const mockStore = createMockStore({
      notifications: [
        {id: '1', message: 'hello'},
        {id: '2', message: 'world'},
      ],
    })

    subscribeFlashNotifications(mockStore)
    mockStore.mockStateChange()

    setTimeout(() => {
      expect(FlashAlert.showFlashAlert).toHaveBeenCalledTimes(2)
      expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({id: '1', message: 'hello'})
      expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({id: '2', message: 'world'})

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

    subscribeFlashNotifications(mockStore)
    mockStore.mockStateChange()

    setTimeout(() => {
      expect(mockStore.dispatch).toHaveBeenCalledTimes(2)
      expect(mockStore.dispatch).toHaveBeenCalledWith(notificationActions.clearNotification('1'))
      expect(mockStore.dispatch).toHaveBeenCalledWith(notificationActions.clearNotification('2'))

      done()
    }, 1)
  })
})

describe('notificationActions', () => {
  test('notifyInfo creates action NOTIFY_INFO with type "info" and payload', () => {
    const action = notificationActions.notifyInfo({message: 'test'})
    expect(action).toEqual({type: 'NOTIFY_INFO', payload: {type: 'info', message: 'test'}})
  })

  test('notifyError creates action NOTIFY_ERROR with type "error" and payload', () => {
    const action = notificationActions.notifyError({message: 'test'})
    expect(action).toEqual({type: 'NOTIFY_ERROR', payload: {type: 'error', message: 'test'}})
  })

  test('clearNotification creates action CLEAR_NOTIFICATION', () => {
    const action = notificationActions.clearNotification()
    expect(action).toEqual({type: 'CLEAR_NOTIFICATION'})
  })
})

describe('reduceNotifications', () => {
  test('catches any action with err and message and treats it as an error notification', () => {
    const action = {
      type: '_NOT_A_REAL_ACTION_',
      payload: {message: 'hello world', err: 'bad things happened'},
    }
    const newState = reduceNotifications([], action)
    expect(newState).toMatchObject([
      {type: 'error', message: 'hello world', err: 'bad things happened'},
    ])
  })

  test('adds new info notification on NOTIFY_INFO', () => {
    const newState = reduceNotifications(
      [],
      notificationActions.notifyInfo({message: 'hello world'})
    )
    expect(newState).toMatchObject([{type: 'info', message: 'hello world'}])
  })

  test('adds new error notification on NOTIFY_ERROR', () => {
    const newState = reduceNotifications(
      [],
      notificationActions.notifyError({message: 'hello world', err: 'bad things happened'})
    )
    expect(newState).toMatchObject([
      {type: 'error', message: 'hello world', err: 'bad things happened'},
    ])
  })

  test('removes notification on CLEAR_NOTIFICATION', () => {
    const newState = reduceNotifications(
      [{id: '1', message: 'hello world', type: 'info'}],
      notificationActions.clearNotification('1')
    )
    expect(newState).toEqual([])
  })
})
