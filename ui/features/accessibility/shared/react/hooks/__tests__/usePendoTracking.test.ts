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

import {renderHook} from '@testing-library/react-hooks'
import {vi} from 'vitest'
import {usePendoTracking} from '../usePendoTracking'
import * as PendoModule from '@canvas/pendo'

describe('usePendoTracking', () => {
  const mockTrack = vi.fn()
  const mockPendo = {
    track: mockTrack,
  }

  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(PendoModule, 'initializePendo').mockResolvedValue(mockPendo)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('handles events with props', async () => {
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({
      eventName: 'EventWithProps',
      props: {courseId: '123'},
    })

    expect(mockTrack).toHaveBeenCalledWith('EventWithProps', {
      courseId: '123',
    })
  })

  it('handles events with no props', async () => {
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({
      eventName: 'PageViewed',
    })

    expect(mockTrack).toHaveBeenCalledWith('PageViewed')
  })

  it('handles empty props object', async () => {
    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({
      eventName: 'ButtonClicked',
      props: {},
    })

    expect(mockTrack).toHaveBeenCalledWith('ButtonClicked')
  })

  it('does not track when pendo is not configured', async () => {
    vi.spyOn(PendoModule, 'initializePendo').mockResolvedValue(null)

    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({
      eventName: 'ButtonClicked',
    })

    expect(mockTrack).not.toHaveBeenCalled()
  })

  it('handles errors gracefully', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error')
    vi.spyOn(PendoModule, 'initializePendo').mockRejectedValue(new Error('Init failed'))

    const {result} = renderHook(() => usePendoTracking())

    await result.current.trackEvent({
      eventName: 'ButtonClicked',
    })

    expect(consoleErrorSpy).toHaveBeenCalledWith(`Failed to track Pendo event: ButtonClicked`)
    expect(mockTrack).not.toHaveBeenCalled()
  })
})
