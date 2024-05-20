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

export type DeepLinkEvent = MessageEvent<{
  subject: 'LtiDeepLinkingResponse'
}>

export type DeepLinkCallback = (e: DeepLinkEvent) => Promise<void>

const deepLinkingResponseMessageType = 'LtiDeepLinkingResponse'

/**
 *Checks to see if a postMessage event is valid for
 * deep linking content item processing
 * the RCE handles deep linking separately in
 * packages/canvas-rce/src/rce/plugins/instructure_rce_external_tools/components/ExternalToolDialog/ExternalToolDialog.tsx
 * @param event
 * @param env
 * @returns
 */
export function isValidDeepLinkingEvent(
  event: MessageEvent,
  env: {DEEP_LINKING_POST_MESSAGE_ORIGIN: string}
): event is MessageEvent<{subject: 'LtiDeepLinkingResponse'}> {
  return !!(
    event.origin === env.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
    event.data?.subject === deepLinkingResponseMessageType &&
    event.data?.placement !== 'editor_button'
  )
}

/**
 * Registers a new listener for DeepLinking messages
 * coming from an embedded tool
 * @param cb the handler which will be called on a DeepLinking message
 * @returns a function which will remove the event listener
 */
export const addDeepLinkingListener = (cb: DeepLinkCallback) => {
  const handler = handleDeepLinking(cb)
  window.addEventListener('message', handler)
  return () => {
    window.removeEventListener('message', handler)
  }
}

export const handleDeepLinking = (cb: DeepLinkCallback) => async (event: MessageEvent) => {
  // Don't attempt to process invalid messages
  if (!isValidDeepLinkingEvent(event, ENV)) {
    return
  }

  await cb(event)
}

export const reloadPage = () => {
  window.location.reload()
}
