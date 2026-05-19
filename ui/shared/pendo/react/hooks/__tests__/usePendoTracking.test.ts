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

import {renderHook} from '@testing-library/react-hooks'
import {vi} from 'vitest'
import {usePendoTracking} from '../usePendoTracking'
import * as PendoModule from '@canvas/pendo'

describe('usePendoTracking', () => {
  const mockTrack = vi.fn()
  const mockPendo = {track: mockTrack}

  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(PendoModule, 'initializePendo').mockResolvedValue(mockPendo)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('calls pendo.track with event name and props', async () => {
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({
      eventName: 'study_assist_chat-good-response',
      props: {type: 'track'},
    })

    expect(mockTrack).toHaveBeenCalledWith('study_assist_chat-good-response', {type: 'track'})
  })

  it('calls pendo.track with event name only when no props', async () => {
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({eventName: 'PageViewed'})

    expect(mockTrack).toHaveBeenCalledWith('PageViewed')
  })

  it('calls pendo.track with event name only when props is empty', async () => {
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({eventName: 'ButtonClicked', props: {}})

    expect(mockTrack).toHaveBeenCalledWith('ButtonClicked')
  })

  it('does not track when initializePendo resolves to null', async () => {
    vi.spyOn(PendoModule, 'initializePendo').mockResolvedValue(null)
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({eventName: 'ButtonClicked'})

    expect(mockTrack).not.toHaveBeenCalled()
  })

  it('does not track and logs error when initializePendo rejects', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error')
    vi.spyOn(PendoModule, 'initializePendo').mockRejectedValue(new Error('Init failed'))
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({eventName: 'ButtonClicked'})

    expect(consoleErrorSpy).toHaveBeenCalledWith('Failed to track Pendo event: ButtonClicked')
    expect(mockTrack).not.toHaveBeenCalled()
  })
})
