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

import {useCallback} from 'react'
import {initializePendo} from '@canvas/pendo'

export interface PendoTrackingEvent {
  eventName: string
  props?: Record<string, any>
}

export const usePendoTracking = () => {
  const trackEvent = useCallback(async (event: PendoTrackingEvent): Promise<void> => {
    try {
      const pendo = await initializePendo()

      if (!pendo) {
        return
      }

      if (event.props && Object.keys(event.props).length > 0) {
        pendo.track(event.eventName, event.props)
      } else {
        pendo.track(event.eventName)
      }
    } catch {
      console.error(`Failed to track Pendo event: ${event.eventName}`)
    }
  }, [])

  return {trackEvent}
}
