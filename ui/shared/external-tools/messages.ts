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

export type ExternalContentReady = {
  subject: 'externalContentReady'
  contentItems: Lti1p1ContentItem[]
  service: Service
}

export type Lti1p1ContentItem = {
  '@type': 'FileItem' | 'LtiLinkItem'
  url: string
  // TODO: all possible values defined at https://www.imsglobal.org/specs/lticiv1p0/specification
}

export type HandleOptions = {
  ready?: (data: ExternalContentReady) => Promise<void> | void
  cancel?: () => Promise<void> | void
  env?: any
  service?: Service
}

export const handleExternalContentMessages = ({
  ready = () => {},
  cancel = () => {},
  env = window.ENV,
  service,
}: HandleOptions) => {
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
