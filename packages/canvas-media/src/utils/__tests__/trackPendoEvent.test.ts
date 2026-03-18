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

import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'
import {trackPendoEvent} from '../trackPendoEvent'

describe('trackPendoEvent', () => {
  const mockTrack = vi.fn()

  beforeEach(() => {
    ;(window as any).canvasUsageMetrics = {track: mockTrack}
  })

  afterEach(() => {
    vi.clearAllMocks()
    delete (window as any).canvasUsageMetrics
  })

  it('calls pendo.track with event name and props including type track', () => {
    trackPendoEvent('test_event', {foo: 'bar'})
    expect(mockTrack).toHaveBeenCalledWith('test_event', {type: 'track', foo: 'bar'})
  })

  it('calls pendo.track with type track when props are omitted', () => {
    trackPendoEvent('test_event')
    expect(mockTrack).toHaveBeenCalledWith('test_event', {type: 'track'})
  })

  it('does nothing when pendo is not available', () => {
    delete (window as any).canvasUsageMetrics
    trackPendoEvent('test_event')
    expect(mockTrack).not.toHaveBeenCalled()
  })

  it('does not throw when track throws', () => {
    mockTrack.mockImplementation(() => {
      throw new Error('track failed')
    })
    expect(() => trackPendoEvent('test_event')).not.toThrow()
  })
})
