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

export const EXTERNAL_CONTENT_READY = 'externalContentReady'
export const EXTERNAL_CONTENT_CANCEL = 'externalContentCancel'

export type Service = 'equella' | 'external_tool_dialog' | 'external_tool_redirect'

export type ExternalContentReadyInnerData = {
  contentItems: Lti1p1ContentItem[]
  service: Service

  // for editing collaborations. currently comes in thru ENV as a stringified
  // number, but it doesn't matter as it's just interpolated in a URL.
  service_id: number | string
}
export type ExternalContentReady = ExternalContentReadyInnerData & {
  subject: typeof EXTERNAL_CONTENT_READY
}

// TODO in one place we send a message with "service_id"
// so  probably add
//   service_id?: string
//  (double-check it's a string)

export type Lti1p1ContentItem = {
  '@type': 'FileItem' | 'LtiLinkItem'
  url: string
  // TODO: all possible values defined at https://www.imsglobal.org/specs/lticiv1p0/specification
  // also see usages/type definitions in:
  //   - handleExternalContentReady in packages/canvas-rce/.../ExternalToolDialog.tsx
  //   - externalContentReadyHandler in ui/shared/select-content-dialog/jquery/select_content_dialog.tsx
  //   - other files using handleExternalContentMessages and postMessageExternalContentReady
}

export type HandleOptions = {
  ready?: (data: ExternalContentReady) => Promise<void> | void
  cancel?: () => Promise<void> | void
  env?: any
  service?: Service
}

export type MessageHandlerCleanupFunction = () => void

/**
 * Sets up handlers to listen to externalContentReady and/or
 * externalContentCancel postMessages. These messages are sent from Canvas
 * inside the tool iframe, after redirecting to the external content success
 * URL. Success messages contain content items provided by the tool for
 * processing.
 *
 * Returns a function that removes the listener.
 */
export const handleExternalContentMessages = ({
  ready = _data => {},
  cancel = () => {},
  env = window.ENV,
  service,
}: HandleOptions): MessageHandlerCleanupFunction => {
  const handler = async (event: MessageEvent) => {
    if (event.origin !== env.DEEP_LINKING_POST_MESSAGE_ORIGIN) {
      return false
    }

    if (event.data.subject === EXTERNAL_CONTENT_READY) {
      if (!service || (service && event.data.service === service)) {
        await ready(event.data as ExternalContentReady)
      }
    } else if (event.data.subject === EXTERNAL_CONTENT_CANCEL) {
      await cancel()
    }
  }

  window.addEventListener('message', handler)
  return () => window.removeEventListener('message', handler)
}

export function postMessageExternalContentReady(
  window: Window,
  eventData: ExternalContentReadyInnerData
) {
  window.postMessage(
    {subject: EXTERNAL_CONTENT_READY, ...eventData},
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
  )
}

export function postMessageExternalContentCancel(window: Window) {
  window.postMessage({subject: EXTERNAL_CONTENT_CANCEL}, ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN)
}
