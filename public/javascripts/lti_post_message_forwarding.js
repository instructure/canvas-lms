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

/**
 * Post message forwarding as a static JS file to minimize the size of the forwarder
 * iframe.
 */

// Types:

/**
 * Represents the structure of a message.
 * @typedef {Object} Message
 * @property {Object} sourceToolInfo - Information about the source tool.
 * @property {string} sourceToolInfo.origin - The origin of the source tool.
 * @property {number} sourceToolInfo.windowId - The window ID of the source tool.
 * @property {Object} [key] - Additional properties in the message.
 */

/**
 * Represents an array of window references.
 * @typedef {Array<Window>} WindowReferences
 */

// Functions:

/**
 * Message handler function.
 * @param {string} parentOrigin - The origin of the parent window.
 * @param {WindowReferences} windowReferences - Array of window references.
 * @param {Window|null} parentWindow - The parent window.
 * @param {boolean} includeRCESignal - Flag to include RCE signal in the message.
 * @returns {Function} - Event handler function for message events.
 */
const handler = (parentOrigin, windowReferences, parentWindow, includeRCESignal) => e => {
  /** @type {Message} */
  let message

  try {
    message = typeof e.data === 'string' ? JSON.parse(e.data) : e.data
  } catch (err) {
    // unparseable message may not be meant for our handlers
    return false
  }

  if (e.origin === parentOrigin) {
    // message from canvas -> tool
    const {sourceToolInfo, ...messageWithoutSourceToolInfo} = message

    if (!sourceToolInfo) {
      return false
    }

    const targetOrigin = sourceToolInfo?.origin
    const targetWindow = windowReferences[sourceToolInfo?.windowId]

    targetWindow?.postMessage(messageWithoutSourceToolInfo, targetOrigin)
  } else {
    // message from tool -> canvas
    // We can't forward the whole `e.source` window in the postMessage,
    // so we keep a list (`windowReferences`) of all windows we've received
    // messages from, and include the index into that list as `windowId`

    let windowId = windowReferences.indexOf(e.source)

    if (windowId === -1) {
      windowReferences.push(e.source)
      windowId = windowReferences.length - 1
    }

    const newMessage = {...message, sourceToolInfo: {origin: e.origin, windowId}}

    if (includeRCESignal) {
      newMessage.in_rce = true
    }

    parentWindow?.postMessage(newMessage, parentOrigin)
  }
}

/**
 * Ads a callback function to be executed when the document is ready,
 * or runs immediately if the document is already ready.
 * From @instructure/ready (simplified for use with just one callback)
 */
const ready = callback => {
  const doc = typeof document === 'object' && document
  const loaded = !doc || /^loaded|^i|^c/.test(doc.readyState)
  if (loaded) {
    callback()
  } else {
    const onReady = () => {
      callback()
      doc.removeEventListener('DOMContentLoaded', onReady)
    }
    doc.addEventListener('DOMContentLoaded', onReady)
  }
}

// Main entry point, Initializes the message handling when the document is ready.
const init = () => {
  ready(() => {
    const {PARENT_ORIGIN, IN_RCE} = window.ENV

    /** @type {WindowReferences} */
    const windowReferences = []

    if (IN_RCE) {
      // Canvas renders the RCE/TinyMCE, which uses an iframe to enclose the content being edited
      // tools inside the editor should send _all_ postMessages directly to Canvas.
      const canvasWindow = window.parent.parent
      window.addEventListener(
        'message',
        handler(window.origin, windowReferences, canvasWindow, true)
      )
    } else {
      window.addEventListener('message', handler(PARENT_ORIGIN, windowReferences, window.top))
    }
  })
}

if (typeof jest === 'undefined') {
  init()
} else {
  module.exports = {handler, init}
}
