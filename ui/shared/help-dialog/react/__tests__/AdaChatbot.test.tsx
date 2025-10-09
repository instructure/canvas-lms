// Copyright (C) 2025 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render, cleanup} from '@testing-library/react'
import {captureException} from '@sentry/react'
import AdaChatbot from '../AdaChatbot'

jest.mock('@sentry/react', () => ({
  captureException: jest.fn(),
}))

const mockCaptureException = captureException as jest.MockedFunction<typeof captureException>

describe('AdaChatbot', () => {
  const mockOnSubmit = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
    delete (window as any).adaEmbed
    mockCaptureException.mockClear()
  })

  afterEach(() => {
    cleanup()
  })

  it('renders nothing as expected', () => {
    const {container} = render(<AdaChatbot onSubmit={mockOnSubmit} />)
    expect(container.firstChild).toBeNull()
  })

  it('calls callback on mount (closing the help menu)', () => {
    render(<AdaChatbot onSubmit={mockOnSubmit} />)
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
  })

  it('does not initialize Ada when unavailable', () => {
    const mockStart = jest.fn()
    render(<AdaChatbot onSubmit={mockOnSubmit} />)
    expect(mockStart).not.toHaveBeenCalled()
  })

  it('initializes Ada when available', () => {
    const mockStart = jest.fn()
    const mockToggle = jest.fn()
    const mockStop = jest.fn()
    ;(window as any).adaEmbed = {
      start: mockStart,
      toggle: mockToggle,
      stop: mockStop,
    }

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    expect(mockStart).toHaveBeenCalledTimes(1)
    expect(mockStart).toHaveBeenCalledWith(
      expect.objectContaining({
        handle: 'instructure-gen',
        adaReadyCallback: expect.any(Function),
        toggleCallback: expect.any(Function),
      }),
    )
  })

  it('injects global adaSettings metaFields and preserves explicit handle override', () => {
    const mockStart = jest.fn()
    const mockToggle = jest.fn()
    const mockStop = jest.fn()
    const globalSettings = {
      crossWindowPersistence: true,
      metaFields: {
        institutionUrl: 'https://example.instructure.com',
        email: 'user@example.com',
        name: 'Test User',
        canvasRoles: 'teacher,admin',
        canvasUUID: 'abc-123',
        isRootAdmin: false,
        isAdmin: true,
        isTeacher: true,
        isStudent: false,
        isObserver: false,
      },
      handle: 'should-be-overridden',
    }
    ;(window as any).adaEmbed = {
      start: mockStart,
      toggle: mockToggle,
      stop: mockStop,
    }
    ;(window as any).adaSettings = globalSettings

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    expect(mockStart).toHaveBeenCalledTimes(1)
    const passedConfig = mockStart.mock.calls[0][0]

    expect(passedConfig.metaFields).toEqual(globalSettings.metaFields)
    expect(passedConfig.crossWindowPersistence).toBe(true)
    expect(passedConfig.handle).toBe('instructure-gen')
    expect(globalSettings.handle).toBe('should-be-overridden')
  })

  it('opens when ready and clears timeout', () => {
    jest.useFakeTimers()
    const mockStart = jest.fn()
    const mockToggle = jest.fn()
    const mockStop = jest.fn()
    ;(window as any).adaEmbed = {
      start: mockStart,
      toggle: mockToggle,
      stop: mockStop,
    }

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    const startCallArgs = mockStart.mock.calls[0][0]
    const adaReadyCallback = startCallArgs.adaReadyCallback

    adaReadyCallback()

    expect(mockToggle).toHaveBeenCalledTimes(1)
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)

    jest.advanceTimersByTime(10000)
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)

    jest.useRealTimers()
  })

  it('removes Ada when chat is closed', () => {
    const mockStart = jest.fn()
    const mockToggle = jest.fn()
    const mockStop = jest.fn()
    ;(window as any).adaEmbed = {
      start: mockStart,
      toggle: mockToggle,
      stop: mockStop,
    }

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    const startCallArgs = mockStart.mock.calls[0][0]
    const toggleCallback = startCallArgs.toggleCallback

    toggleCallback(false)

    expect(mockStop).toHaveBeenCalledTimes(1)
  })

  it('does not remove Ada when chat is opened', () => {
    const mockStart = jest.fn()
    const mockToggle = jest.fn()
    const mockStop = jest.fn()
    ;(window as any).adaEmbed = {
      start: mockStart,
      toggle: mockToggle,
      stop: mockStop,
    }

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    const startCallArgs = mockStart.mock.calls[0][0]
    const toggleCallback = startCallArgs.toggleCallback

    toggleCallback(true)

    expect(mockStop).not.toHaveBeenCalled()
  })

  it('calls onSubmit after timeout when Ada fails to connect', () => {
    jest.useFakeTimers()
    const mockStart = jest.fn()
    ;(window as any).adaEmbed = {
      start: mockStart,
    }

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    expect(mockStart).toHaveBeenCalledTimes(1)
    expect(mockOnSubmit).not.toHaveBeenCalled()

    jest.advanceTimersByTime(10000)

    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
    jest.useRealTimers()
  })

  it('handles Ada initialization errors gracefully', () => {
    const mockStart = jest.fn().mockImplementation(() => {
      throw new Error('Ada initialization failed')
    })
    ;(window as any).adaEmbed = {
      start: mockStart,
    }

    render(<AdaChatbot onSubmit={mockOnSubmit} />)

    expect(mockCaptureException).toHaveBeenCalledWith(expect.any(Error))
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
  })
})
