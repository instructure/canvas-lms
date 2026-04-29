/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEffect, useRef} from 'react'
import {openWindow} from '@canvas/util/globalUtils'

type AdaChatbotProps = {
  onDialogClose: () => void
}

// Canvas-hosted popup page — Ada SDK loads here and receives metadata via
// postMessage. PII never appears in a URL.
const ADA_POPUP_PATH = '/ada_chat_popup'

// Keep in sync with the string literals in app/views/ada_chat_popup/show.html.erb
export const ADA_MSG_POPUP_READY = 'ADA_POPUP_READY' as const
export const ADA_MSG_META_FIELDS = 'ADA_META_FIELDS' as const

/**
 * Checks if Ada chatbot is enabled via feature flag.
 */
function isAdaEnabled(): boolean {
  if (typeof window === 'undefined' || !window.ENV) {
    return false
  }
  return window.ENV.ADA_CHATBOT_ENABLED === true
}

/**
 * Metadata split into plain (metaFields) and encrypted (sensitiveMetaFields) buckets.
 * Ada encrypts sensitiveMetaFields immediately on receipt and does not persist them.
 */
export type AdaMetaFieldsResult = {
  metaFields: Record<string, string>
  sensitiveMetaFields: Record<string, string>
}

/**
 * Builds Ada metadata split into plain and sensitive buckets.
 */
export function getAdaMetaFields(): AdaMetaFieldsResult {
  const user = window.ENV?.current_user || {}
  const roles: string[] = window.ENV?.current_user_roles || []
  const roleSet = new Set(roles)
  const domainRootAccountUuid = window.ENV?.DOMAIN_ROOT_ACCOUNT_UUID || ''

  return {
    sensitiveMetaFields: {
      email: user.email || '',
      name: user.display_name || '',
    },
    metaFields: {
      launchedUrl: window.location.href,
      institutionUrl: window.location.origin,
      canvasRoles: roles.join(','),
      canvasUUID: domainRootAccountUuid,
      isRootAdmin: String(roleSet.has('root_admin')),
      isAdmin: String(roleSet.has('admin')),
      isTeacher: String(roleSet.has('teacher')),
      isStudent: String(roleSet.has('student')),
      isObserver: String(roleSet.has('observer')),
    },
  }
}

// Tracks the pending ready listener so it can be replaced if the popup is
// already open and won't re-send ADA_POPUP_READY.
let pendingReadyListener: ((event: MessageEvent) => void) | null = null

/**
 * Opens the Ada chatbot popup. The popup page is Canvas-hosted; once it
 * signals ready, metadata is forwarded via same-origin postMessage so PII
 * is never exposed in a URL.
 */
export function launchAdaPopup(): void {
  if (pendingReadyListener) {
    window.removeEventListener('message', pendingReadyListener)
  }

  const {metaFields, sensitiveMetaFields} = getAdaMetaFields()
  openWindow(ADA_POPUP_PATH, 'AdaChatPopup', 'width=500,height=700,resizable=yes,scrollbars=yes')

  const listener = (event: MessageEvent) => {
    if (event.origin !== window.location.origin) return
    if (event.data?.type !== ADA_MSG_POPUP_READY) return
    window.removeEventListener('message', listener)
    pendingReadyListener = null
    const source = event.source as Window | null
    source?.postMessage(
      {type: ADA_MSG_META_FIELDS, metaFields, sensitiveMetaFields},
      window.location.origin,
    )
  }

  pendingReadyListener = listener
  window.addEventListener('message', listener)
}

/**
 * AdaChatbot opens the Ada chatbot in a popup window when the user selects it
 * from the help menu, then closes the help dialog.
 */
function AdaChatbot({onDialogClose}: AdaChatbotProps) {
  const launched = useRef(false)

  useEffect(() => {
    if (launched.current) return
    launched.current = true
    if (isAdaEnabled()) {
      launchAdaPopup()
    }
    onDialogClose()
  }, [onDialogClose])

  return null
}

export default AdaChatbot
