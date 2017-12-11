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

import { createActions, handleActions } from 'redux-actions'
import { showFlashAlert } from './FlashAlert'

/**
 * Exports action action creators for notification actions:
 * - notifyInfo(string | { message })
 * - notifyError(string | { err, message })
 * - clearNotifications()
 */
export const notificationActions = createActions({
  NOTIFY_INFO: payload =>
    typeof payload === 'string'
      ? { type: 'info', message: payload }
      : { type: 'info', ...payload },
  NOTIFY_ERROR: payload =>
    typeof payload === 'string'
    ? { type: 'error', message: payload }
    : { type: 'error', ...payload },
}, 'CLEAR_NOTIFICATION')

const createNotification = data => ({
  id: Math.random().toString(36).substring(2), // pseudo uuid
  timestamp: Date.now(),
  type: data.type || (data.err ? 'error' : 'info'),
  message: data.message,
  err: data.err,
})

const handleNotificationActions = handleActions({
  [notificationActions.notifyInfo.toString()]:
    (state, action) => state.concat([createNotification({ ...action.payload, type: 'info' })]),
  [notificationActions.notifyError.toString()]:
    (state, action) => state.concat([createNotification({ ...action.payload, type: 'error' })]),
  [notificationActions.clearNotification.toString()]:
    (state, action) => state.slice().filter(not => not.id !== action.payload),
}, [])

/**
 * Reducer function for notifications array. Add it in your root reducer!
 * Will add or remove notifications to the state depending on the action
 * It will try to catch generic actions with an `err` and `message` prop on the
 * payload as error notifications
 *
 * @param {array[notification]} state current notifications state
 * @param {action} action action to reduce notification with
 *
 * @example
 * combineReducers({
 *  notifications: reduceNotifications,
 *  items: handleActions({
 *    // your reducer here
 *  }, []),
 *  users: (state, action) => {
 *    // your reducer here
 *  },
 * })
 */
export const reduceNotifications = (state, action) => {
  let newState = handleNotificationActions(state, action)

  const notErr = action.type !== notificationActions.notifyError.toString()
  const looksLikeErr = action.payload && action.payload.err && action.payload.message

  // duck typing error notifications from structure of _FAIL actions
  if (notErr && looksLikeErr) {
    newState = newState.concat([createNotification(action.payload)])
  }

  return newState
}

/**
 * This function watches the given store for notifications, and flashes an
 * alert component for every one of them
 *
 * @param {store} store redux store to subscribe to
 * @param {string} key optional state key to look look into store state for notifications
 */
export function subscribeFlashNotifications (store, key = 'notifications') {
  store.subscribe(() => {
    const notifications = store.getState()[key]
    notifications.forEach((notification) => {
      showFlashAlert(notification)
      store.dispatch(notificationActions.clearNotification(notification.id))
    })
  })
}
