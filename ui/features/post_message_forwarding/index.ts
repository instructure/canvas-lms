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
  sourceToolInfo?: {
    origin: string
    windowId: number
  }
  [key: string]: any
}

type WindowReferences = [Window]

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

    // NOTE: the code to encode/decode `sourceToolInfo` is duplicated in
    // the RCE code (packages/canvas-rce/src/rce/RCEWrapper.jsx), and
    // cannot be DRY'd because RCE is in a package
    if (e.origin === PARENT_ORIGIN) {
      const {sourceToolInfo, ...messageWithoutSourceToolInfo} = message
      if (!sourceToolInfo) {
        return false
      }
      const targetOrigin = sourceToolInfo?.origin
      const targetWindow = windowReferences[sourceToolInfo?.windowId]
      targetWindow?.postMessage(messageWithoutSourceToolInfo, targetOrigin)
    } else {
      // We can't forward the whole `e.source` window in the postMessage,
      // so we keep a list (`windowReferences`) of all windows we've received
      // messages from, and include the index into that list as `windowId`
      let windowId = windowReferences.indexOf(e.source)
      if (windowId === -1) {
        windowReferences.push(e.source)
        windowId = windowReferences.length - 1
      }
      const newMessage = {...message, sourceToolInfo: {origin: e.origin, windowId}}
      parentWindow?.postMessage(newMessage, PARENT_ORIGIN)
    }
  }

ready(() => {
  const {PARENT_ORIGIN} = window.ENV as EnvPlatformStoragePostMessageForwarding
  const windowReferences = [] as WindowReferences
  window.addEventListener('message', handler(PARENT_ORIGIN, windowReferences, window.top))
})
