/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {
  KEY_NAMES,
  TRUSTED_MESSAGE_ORIGIN,
  NAVIGATION_MESSAGE,
  INPUT_CHANGE_MESSAGE,
  SELECTION_MESSAGE,
} from './constants'

/**
 * Creates an object representing a navigation event
 *
 * up/down arrows are examples of key presses that
 * would broadcast this type of event
 *
 * @param Event event
 * @returns The navigation message object
 */
export function navigationMessage(event) {
  return {subject: NAVIGATION_MESSAGE, value: KEY_NAMES[event.which] || event.which}
}

/**
 * Creates an object representing an input change
 *
 * Changing the text after the "@" symbol is an
 * event that would broadcast this type of event
 *
 * @param String value - the current value of the text after @
 * @returns The input change message object
 */
export function inputChangeMessage(value) {
  return {subject: INPUT_CHANGE_MESSAGE, value}
}

export function selectionMessage(event) {
  return {subject: SELECTION_MESSAGE, value: KEY_NAMES[event.which] || event.which}
}

/**
 * Sends the specified message to each given window
 * via postMessage.
 *
 * Only broadcasts to the window if that window's origin
 * matches that of the current Canvas page.
 *
 * @param Object message
 * @param Object[] windows
 */
function broadcastMessage(message, windows) {
  windows.forEach(w => {
    w.postMessage(message, TRUSTED_MESSAGE_ORIGIN)
  })
}

export default broadcastMessage
