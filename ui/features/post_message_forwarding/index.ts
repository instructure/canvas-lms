// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import ready from '@instructure/ready'
import {EnvPlatformStoragePostMessageForwarding} from '@canvas/global/env/EnvPlatformStorage'

type Message = {
  toolOrigin?: string
  [key: string]: any
}

type WindowReferences = {
  [origin: string]: Window
}

export const handler =
  (PARENT_ORIGIN: string, windowReferences: WindowReferences, parentWindow: Window | null) =>
  (e: MessageEvent) => {
    let message: Message
    try {
      message = typeof e.data === 'string' ? JSON.parse(e.data) : e.data
    } catch (err) {
      // unparseable message may not be meant for our handlers
      return false
    }

    if (e.origin === PARENT_ORIGIN) {
      // message is from Canvas window, forward to tool
      const targetOrigin = message.toolOrigin
      if (!targetOrigin) {
        return false
      }

      const targetWindow = windowReferences[targetOrigin]
      delete message.toolOrigin

      targetWindow?.postMessage(message, targetOrigin)
    } else {
      // message is from tool, forward to Canvas window
      windowReferences[e.origin] = e.source
      message.toolOrigin = e.origin

      parentWindow?.postMessage(message, PARENT_ORIGIN)
    }
  }

ready(() => {
  const {PARENT_ORIGIN} = window.ENV as EnvPlatformStoragePostMessageForwarding
  const windowReferences = {} as WindowReferences
  window.addEventListener('message', handler(PARENT_ORIGIN, windowReferences, window.top))
})
