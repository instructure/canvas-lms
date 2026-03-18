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

import {trackPendoEvent} from '@instructure/canvas-media'

// Matches TrackEvent from @instructure/studio-player
type TrackEvent =
  | {type: 'transcript_search'; searchTerm: string}
  | {type: 'transcript_timestamp_click'; timestamp: number}
  | {type: 'transcript_auto_follow_toggle'; enabled: boolean}
  | {type: 'fullscreen_toggled'; isFullScreen: boolean}
  | {type: 'sidebar_visibility_changed'; isVisible: boolean}

export function createPendoTrackEventHandler(): (event: TrackEvent) => void {
  return (event: TrackEvent) => {
    switch (event.type) {
      case 'fullscreen_toggled':
        trackPendoEvent('studio_fullscreen_toggled', {
          state: event.isFullScreen ? 'entered' : 'exited',
        })
        break
      case 'transcript_search':
        trackPendoEvent('canvas_transcript_interaction', {
          interaction_type: 'search',
          search_term: event.searchTerm,
        })
        break
      case 'transcript_timestamp_click':
        trackPendoEvent('canvas_transcript_interaction', {
          interaction_type: 'timestamp_click',
          timestamp: event.timestamp,
        })
        break
      case 'transcript_auto_follow_toggle':
        trackPendoEvent('canvas_transcript_interaction', {
          interaction_type: 'auto_follow_toggle',
          enabled: event.enabled,
        })
        break
      case 'sidebar_visibility_changed':
        trackPendoEvent('studio_sidebox_visibility_changed', {
          visibility_state: event.isVisible ? 'shown' : 'hidden',
        })
        break
    }
  }
}
