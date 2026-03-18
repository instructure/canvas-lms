/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const SR_HOLDER_ID = 'flash_screenreader_holder'

// Track pending timeout so we can cancel on rapid successive calls
let pendingAnnouncementTimeout: ReturnType<typeof setTimeout> | null = null

/**
 * Announces a message to screen readers after a delay.
 * The delay allows focus to settle after DOM changes.
 *
 * @param message - The message to announce to screen readers
 */
export function announceToScreenReader(message: string): void {
  if (pendingAnnouncementTimeout) {
    clearTimeout(pendingAnnouncementTimeout)
    pendingAnnouncementTimeout = null
  }

  pendingAnnouncementTimeout = setTimeout(() => {
    // Remove the existing SR holder to prevent accumulation of
    // identical messages. showFlashAlert's getLiveRegion() will
    // create a fresh role="alert" element automatically.
    document.getElementById(SR_HOLDER_ID)?.remove()

    showFlashAlert({message, srOnly: true, politeness: 'polite'})
    pendingAnnouncementTimeout = null
  }, 1000)
}
