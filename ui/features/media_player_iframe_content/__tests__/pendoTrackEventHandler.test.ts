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

import {describe, expect, it, vi} from 'vitest'
import {createPendoTrackEventHandler} from '../pendoTrackEventHandler'

vi.mock('@instructure/canvas-media', () => ({
  trackPendoEvent: vi.fn(),
}))

import {trackPendoEvent} from '@instructure/canvas-media'

const mockTrackPendoEvent = vi.mocked(trackPendoEvent)

describe('createPendoTrackEventHandler', () => {
  beforeEach(() => {
    mockTrackPendoEvent.mockClear()
  })

  const handler = createPendoTrackEventHandler()

  describe('fullscreen_toggled', () => {
    it('tracks entered state when entering fullscreen', () => {
      handler({type: 'fullscreen_toggled', isFullScreen: true})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('studio_fullscreen_toggled', {
        state: 'entered',
      })
    })

    it('tracks exited state when leaving fullscreen', () => {
      handler({type: 'fullscreen_toggled', isFullScreen: false})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('studio_fullscreen_toggled', {
        state: 'exited',
      })
    })
  })

  describe('transcript_search', () => {
    it('tracks search interaction with search term', () => {
      handler({type: 'transcript_search', searchTerm: 'hello world'})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('canvas_transcript_interaction', {
        interaction_type: 'search',
        search_term: 'hello world',
      })
    })
  })

  describe('transcript_timestamp_click', () => {
    it('tracks timestamp click with timestamp value', () => {
      handler({type: 'transcript_timestamp_click', timestamp: 42.5})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('canvas_transcript_interaction', {
        interaction_type: 'timestamp_click',
        timestamp: 42.5,
      })
    })
  })

  describe('transcript_auto_follow_toggle', () => {
    it('tracks auto follow toggle with enabled state', () => {
      handler({type: 'transcript_auto_follow_toggle', enabled: true})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('canvas_transcript_interaction', {
        interaction_type: 'auto_follow_toggle',
        enabled: true,
      })
    })
  })

  describe('sidebar_visibility_changed', () => {
    it('tracks shown state when sidebar becomes visible', () => {
      handler({type: 'sidebar_visibility_changed', isVisible: true})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('studio_sidebox_visibility_changed', {
        visibility_state: 'shown',
      })
    })

    it('tracks hidden state when sidebar is hidden', () => {
      handler({type: 'sidebar_visibility_changed', isVisible: false})
      expect(mockTrackPendoEvent).toHaveBeenCalledWith('studio_sidebox_visibility_changed', {
        visibility_state: 'hidden',
      })
    })
  })
})
