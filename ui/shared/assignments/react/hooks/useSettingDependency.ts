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

import {useEffect, useCallback} from 'react'

/**
 * Hook to handle setting dependencies in the assignment edit page.
 *
 * When one setting (e.g., moderated grading) disables another (e.g., peer reviews),
 * this hook standardizes the postMessage listening pattern.
 *
 * @param subject - The postMessage subject to listen for (e.g., 'ASGMT.togglePeerReviews')
 * @param handlers - Object containing onDisabled and optional onEnabled callbacks
 *
 * @example
 * // In PeerReviewDetails.tsx
 * useSettingDependency(SETTING_MESSAGES.TOGGLE_PEER_REVIEWS, {
 *   onDisabled: () => {
 *     setPeerReviewEnabled(false)
 *     setPeerReviewChecked(false)
 *   },
 *   onEnabled: () => {
 *     setPeerReviewEnabled(true)
 *   }
 * })
 */
export function useSettingDependency(
  subject: string,
  handlers: {
    onDisabled: () => void
    onEnabled?: () => void
  },
) {
  const {onDisabled, onEnabled} = handlers

  const handleMessage = useCallback(
    (event: MessageEvent) => {
      if (event.data?.subject === subject) {
        if (event.data.enabled === false) {
          onDisabled()
        } else if (event.data.enabled === true && onEnabled) {
          onEnabled()
        }
      }
    },
    [subject, onDisabled, onEnabled],
  )

  useEffect(() => {
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleMessage])
}

/**
 * Known message subjects for setting dependencies.
 * Use these constants instead of magic strings.
 *
 * IMPORTANT: These messages control checkbox INTERACTION state, not checked state:
 *
 * TOGGLE_PEER_REVIEWS:
 *   - enabled: false → Disables checkbox interaction AND unchecks it
 *   - enabled: true  → Enables checkbox interaction only (does NOT check it)
 *
 * This asymmetry is intentional: disabling a feature should turn it off,
 * but re-enabling interaction should let the user decide whether to turn it back on.
 */
export const SETTING_MESSAGES = {
  TOGGLE_PEER_REVIEWS: 'ASGMT.togglePeerReviews',
} as const

export type SettingMessageSubject = (typeof SETTING_MESSAGES)[keyof typeof SETTING_MESSAGES]
