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
import {render, cleanup, waitFor} from '@testing-library/react'
import AdaChatbot from '../AdaChatbot'

const PERSIST_KEY = 'persistedAdaClosed'

describe('AdaChatbot', () => {
  const mockOnDialogClose = jest.fn()
  let mockAdaEmbed: any

  beforeEach(() => {
    jest.clearAllMocks()
    localStorage.clear()
    delete (window as any).adaEmbed
    delete (window as any).adaSettings
    jest.spyOn(console, 'warn').mockImplementation(() => {})
    jest.spyOn(console, 'error').mockImplementation(() => {})

    mockAdaEmbed = {
      start: jest.fn().mockResolvedValue(undefined),
      toggle: jest.fn(),
      getInfo: jest.fn().mockResolvedValue({isChatOpen: false, hasActiveChatter: false}),
    }

    ;(window as any).adaEmbed = mockAdaEmbed
  })

  afterEach(() => {
    cleanup()
    localStorage.clear()
    jest.restoreAllMocks()
  })

  it('renders nothing as expected', () => {
    const {container} = render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    expect(container.firstChild).toBeNull()
  })

  it('calls onDialogClose when opening Ada', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
    })
  })

  it('does nothing when Ada embed is not available', async () => {
    delete (window as any).adaEmbed

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
    })
  })

  it('initializes Ada with correct configuration', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1)
    })

    expect(mockAdaEmbed.start).toHaveBeenCalledWith(
      expect.objectContaining({
        handle: 'instructure-gen',
        hideMascot: true,
        adaReadyCallback: expect.any(Function),
        toggleCallback: expect.any(Function),
      }),
    )
  })

  it('injects global adaSettings and overrides handle', async () => {
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
    ;(window as any).adaSettings = globalSettings

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1)
    })

    const passedConfig = mockAdaEmbed.start.mock.calls[0][0]

    expect(passedConfig.metaFields).toEqual(globalSettings.metaFields)
    expect(passedConfig.crossWindowPersistence).toBe(true)
    expect(passedConfig.handle).toBe('instructure-gen')
    expect(passedConfig.hideMascot).toBe(true)
    expect(globalSettings.handle).toBe('should-be-overridden')
  })

  it('opens Ada when chat is closed', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.getInfo).toHaveBeenCalled()
    })

    expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1)
  })

  it('does not toggle Ada when chat is already open', async () => {
    mockAdaEmbed.getInfo.mockResolvedValue({isChatOpen: true, hasActiveChatter: false})

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.getInfo).toHaveBeenCalled()
    })

    expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
  })

  it('marks chat as open in localStorage when opened', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.toggle).toHaveBeenCalled()
    })

    expect(localStorage.getItem(PERSIST_KEY)).toBe('false')
  })

  it('marks chat as closed in localStorage via toggleCallback', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {toggleCallback} = mockAdaEmbed.start.mock.calls[0][0]

    toggleCallback(false)

    expect(localStorage.getItem(PERSIST_KEY)).toBe('true')
  })

  it('marks chat as open in localStorage via toggleCallback', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {toggleCallback} = mockAdaEmbed.start.mock.calls[0][0]

    toggleCallback(true)

    expect(localStorage.getItem(PERSIST_KEY)).toBe('false')
  })

  it('restores chat when hasActiveChatter and not closed by user', async () => {
    mockAdaEmbed.getInfo.mockResolvedValue({isChatOpen: false, hasActiveChatter: true})

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    expect(mockAdaEmbed.toggle).toHaveBeenCalled()
  })

  it('does not restore chat when hasActiveChatter but was closed by user', async () => {
    localStorage.setItem(PERSIST_KEY, 'true')
    mockAdaEmbed.getInfo
      .mockResolvedValueOnce({isChatOpen: false, hasActiveChatter: true}) // First call from openAda
      .mockResolvedValueOnce({isChatOpen: true, hasActiveChatter: true}) // After toggle

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    // Wait for openAda to complete (which calls toggle once)
    await waitFor(() => {
      expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1)
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    // Should not have made additional toggle calls because wasClosedByUser() returns true
    expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1)
  })

  it('does not toggle when chat is already open in adaReadyCallback', async () => {
    mockAdaEmbed.getInfo.mockResolvedValue({isChatOpen: true, hasActiveChatter: false})

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    // Toggle should not be called in adaReadyCallback since chat is already open
    expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
  })

  it('handles errors in adaReadyCallback gracefully', async () => {
    mockAdaEmbed.getInfo.mockRejectedValue(new Error('getInfo failed'))

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    expect(console.warn).toHaveBeenCalledWith('Ada ready callback failed:', expect.any(Error))
  })

  it('handles Ada initialization errors gracefully', async () => {
    mockAdaEmbed.start.mockRejectedValue(new Error('Ada initialization failed'))

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(console.error).toHaveBeenCalledWith('Failed to open Ada chatbot:', expect.any(Error))
    })

    expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
  })

  it('prevents duplicate initialization with promise caching', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1)
    })
  })
})
