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

import type {
  FlashNotice,
  FlashNotificationContent,
  FlashNotificationType,
} from '../global/env/EnvNotices'

export const FLASH_NOTICE_STORAGE_KEY = 'flash-notices-across-pages'

function buildFlashNotice(
  type: FlashNotificationType,
  content: FlashNotificationContent,
): FlashNotice {
  switch (type) {
    case 'error':
      return {content, type, icon: 'warning'}
    case 'warning':
      return {content, type, icon: 'warning'}
    case 'info':
      return {content, type, icon: 'info'}
    case 'success':
      return {content, type, icon: 'check'}
    default:
      throw new Error(`Unknown flash notice type: ${type}`)
  }
}

/**
 *
 * @param {FlashNotificationType} type
 * @param {FlashNotificationContent} content
 *
 * Adds a new flash notice to be displayed at the next page load.
 * This is useful when the front-end itself is causing navigation,
 * and we want to show a flash notice on the next page.
 */
export function addFlashNoticeForNextPage(
  type: FlashNotificationType,
  content: FlashNotificationContent,
): void {
  const notice = buildFlashNotice(type, content)
  const noticesJSON = sessionStorage.getItem(FLASH_NOTICE_STORAGE_KEY)
  let notices: FlashNotice[]
  try {
    notices = noticesJSON ? JSON.parse(noticesJSON) : []
  } catch {
    notices = []
  }

  notices.push(notice)
  sessionStorage.setItem(FLASH_NOTICE_STORAGE_KEY, JSON.stringify(notices))
}
