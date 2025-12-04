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

const CHAT_CLOSED_KEY = 'persistedAdaClosed'
const DRAWER_OPEN_KEY = 'persistedAdaDrawerOpen'

describe('AdaChatbot', () => {
  const mockOnDialogClose = jest.fn()
  let mockAdaEmbed: any
  let consoleWarnSpy: jest.SpyInstance
  let consoleErrorSpy: jest.SpyInstance

  beforeEach(() => {
    jest.clearAllMocks()
    localStorage.clear()
    delete (window as any).adaEmbed
    delete (window as any).adaSettings
    consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {})
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

    mockAdaEmbed = {
      start: jest.fn().mockResolvedValue(undefined),
      toggle: jest.fn().mockResolvedValue(undefined),
      getInfo: jest.fn().mockResolvedValue({
        isChatOpen: false,
        isDrawerOpen: false,
        hasActiveChatter: false,
        hasClosedChat: false,
      }),
      subscribeEvent: jest.fn().mockResolvedValue(1),
    }
    ;(window as any).adaEmbed = mockAdaEmbed
    mockAdaEmbed.getInfo.mockClear()
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
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    await waitFor(
      () => {
        expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
      },
      {timeout: 5000},
    )
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
        onAdaEmbedLoaded: expect.any(Function),
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
    mockAdaEmbed.getInfo.mockResolvedValue({
      isChatOpen: true,
      isDrawerOpen: true,
      hasActiveChatter: false,
      hasClosedChat: false,
    })

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.getInfo).toHaveBeenCalled()
    })

    expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
  })

  it('marks chat as active and drawer open when opened', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.toggle).toHaveBeenCalled()
    })

    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('true')
  })

  it('does not mark chat closed when minimizing via toggleCallback', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {toggleCallback} = mockAdaEmbed.start.mock.calls[0][0]

    toggleCallback(false)

    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
  })

  it('restores drawer open only when it was previously open and not closed by user', async () => {
    localStorage.setItem(DRAWER_OPEN_KEY, 'true')
    mockAdaEmbed.getInfo.mockResolvedValue({
      isChatOpen: false,
      isDrawerOpen: false,
      hasActiveChatter: true,
      hasClosedChat: false,
    })

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    expect(mockAdaEmbed.toggle).toHaveBeenCalled()
  })

  it('does not restore drawer when chat was explicitly closed by user', async () => {
    localStorage.setItem(CHAT_CLOSED_KEY, 'true')
    localStorage.setItem(DRAWER_OPEN_KEY, 'true')

    // Set up multiple getInfo responses for different calls
    mockAdaEmbed.getInfo
      .mockResolvedValueOnce({
        isChatOpen: false,
        isDrawerOpen: false,
        hasActiveChatter: true,
        hasClosedChat: true,
      })
      .mockResolvedValueOnce({
        isChatOpen: true,
        isDrawerOpen: true,
        hasActiveChatter: true,
        hasClosedChat: false,
      })
      .mockResolvedValueOnce({
        isChatOpen: true,
        isDrawerOpen: true,
        hasActiveChatter: true,
        hasClosedChat: false,
      })

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    // openAda should toggle once (because chat is closed), but adaReadyCallback should not fire
    expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1)
  })

  it('does not toggle when chat is already open in adaReadyCallback', async () => {
    mockAdaEmbed.getInfo.mockResolvedValue({
      isChatOpen: true,
      isDrawerOpen: true,
      hasActiveChatter: false,
      hasClosedChat: false,
    })

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]
    await adaReadyCallback()

    expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
  })

  it('handles errors in adaReadyCallback gracefully', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {adaReadyCallback} = mockAdaEmbed.start.mock.calls[0][0]

    mockAdaEmbed.getInfo.mockRejectedValueOnce(new Error('getInfo failed'))
    await adaReadyCallback()

    expect(consoleWarnSpy).toHaveBeenCalledWith('Ada ready callback failed:', expect.any(Error))
  })

  it('handles Ada initialization errors gracefully', async () => {
    mockAdaEmbed.start.mockRejectedValue(new Error('Ada initialization failed'))

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(consoleErrorSpy).toHaveBeenCalledWith('Failed to open Ada chatbot:', expect.any(Error))
    })

    await waitFor(() => {
      expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
    })
  })

  it('prevents duplicate initialization with promise caching', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1)
    })
  })

  it('handles toggle timeout gracefully', async () => {
    mockAdaEmbed.toggle.mockImplementation(
      () =>
        new Promise((_resolve, reject) =>
          setTimeout(() => reject(new Error('Toggle timed out')), 10),
        ),
    )

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(
      () => {
        expect(consoleErrorSpy).toHaveBeenCalledWith(
          'Failed to open Ada chatbot:',
          expect.any(Error),
        )
      },
      {timeout: 6000},
    )

    expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
  })

  it('handles getInfo timeout gracefully', async () => {
    mockAdaEmbed.getInfo.mockImplementation(
      () =>
        new Promise((_resolve, reject) =>
          setTimeout(() => reject(new Error('getInfo timed out')), 10),
        ),
    )

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(
      () => {
        expect(consoleErrorSpy).toHaveBeenCalledWith(
          'Failed to open Ada chatbot:',
          expect.any(Error),
        )
      },
      {timeout: 6000},
    )

    expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
  })

  it('uses initial state after toggle completes', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1)
    })

    expect(mockAdaEmbed.getInfo).toHaveBeenCalledTimes(1)
  })

  it('marks chat closed and drawer closed on end conversation event', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {onAdaEmbedLoaded} = mockAdaEmbed.start.mock.calls[0][0]
    onAdaEmbedLoaded()

    // Simulate end conversation event by invoking the callback passed to subscribeEvent
    type SubscribeArgs = [eventKey: string, callback: () => void]
    const subscribeCall = (mockAdaEmbed.subscribeEvent.mock.calls as SubscribeArgs[]).find(
      (call: SubscribeArgs) => call[0] === 'ada:end_conversation',
    )

    expect(subscribeCall).toBeDefined()
    const callback = subscribeCall![1]
    callback()

    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('true')
    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
  })

  it('marks drawer closed but keeps chat active flag on minimize_chat', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {onAdaEmbedLoaded} = mockAdaEmbed.start.mock.calls[0][0]
    onAdaEmbedLoaded()

    type SubscribeArgs = [eventKey: string, callback: () => void]
    const subscribeCall = (mockAdaEmbed.subscribeEvent.mock.calls as SubscribeArgs[]).find(
      (call: SubscribeArgs) => call[0] === 'ada:minimize_chat',
    )

    expect(subscribeCall).toBeDefined()
    const callback = subscribeCall![1]
    callback()

    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
  })

  it('marks drawer closed but does not mark chat closed on close_chat', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

    await waitFor(() => {
      expect(mockAdaEmbed.start).toHaveBeenCalled()
    })

    const {onAdaEmbedLoaded} = mockAdaEmbed.start.mock.calls[0][0]
    onAdaEmbedLoaded()

    type SubscribeArgs = [eventKey: string, callback: () => void]
    const subscribeCall = (mockAdaEmbed.subscribeEvent.mock.calls as SubscribeArgs[]).find(
      (call: SubscribeArgs) => call[0] === 'ada:close_chat',
    )

    expect(subscribeCall).toBeDefined()
    const callback = subscribeCall![1]
    callback()

    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
  })

  describe('autoRestoreAda', () => {
    it('initializes Ada when not closed by user', async () => {
      jest.isolateModules(() => {
        localStorage.setItem(CHAT_CLOSED_KEY, 'false')
        const {autoRestoreAda} = require('../AdaChatbot')

        autoRestoreAda()
      })

      await waitFor(() => {
        expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1)
      })
    })

    it('does not initialize Ada when closed by user', async () => {
      jest.isolateModules(() => {
        localStorage.setItem(CHAT_CLOSED_KEY, 'true')
        const {autoRestoreAda} = require('../AdaChatbot')

        autoRestoreAda()
      })

      // Give any async operations a chance to complete
      await new Promise(resolve => setTimeout(resolve, 50))

      expect(mockAdaEmbed.start).not.toHaveBeenCalled()
    })

    it('only runs once even when called multiple times', async () => {
      jest.isolateModules(() => {
        localStorage.setItem(CHAT_CLOSED_KEY, 'false')
        const {autoRestoreAda} = require('../AdaChatbot')

        autoRestoreAda()
        autoRestoreAda()
        autoRestoreAda()
      })

      await waitFor(() => {
        expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1)
      })
    })

    it('handles initialization errors gracefully', async () => {
      let errorSpy: jest.SpyInstance

      jest.isolateModules(() => {
        localStorage.setItem(CHAT_CLOSED_KEY, 'false')

        // Set up the mock to reject before importing the module
        const failingAdaEmbed = {
          start: jest.fn().mockRejectedValue(new Error('Init failed')),
          toggle: jest.fn(),
          getInfo: jest.fn().mockResolvedValue({
            isChatOpen: false,
            isDrawerOpen: false,
            hasActiveChatter: false,
            hasClosedChat: false,
          }),
          subscribeEvent: jest.fn().mockResolvedValue(1),
        }
        ;(window as any).adaEmbed = failingAdaEmbed

        errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
        const {autoRestoreAda} = require('../AdaChatbot')

        autoRestoreAda()
      })

      await waitFor(() => {
        expect(errorSpy!).toHaveBeenCalledWith('Failed to auto-restore Ada:', expect.any(Error))
      })

      errorSpy!.mockRestore()
    })

    it('does not assume adaReadyCallback runs on start() resolution', async () => {
      let capturedConfig: any

      jest.isolateModules(() => {
        // Simulate prior drawer state that would cause a restore on ready
        localStorage.setItem(DRAWER_OPEN_KEY, 'true')
        localStorage.setItem(CHAT_CLOSED_KEY, 'false')

        const asyncAdaEmbed = {
          // Resolve start immediately, but do not invoke callbacks here
          start: jest.fn().mockImplementation((config: any) => {
            capturedConfig = config
            return Promise.resolve()
          }),
          toggle: jest.fn().mockResolvedValue(undefined),
          // Pretend chat initially not open, but has active chatter to exercise logic
          getInfo: jest.fn().mockResolvedValue({
            isChatOpen: false,
            isDrawerOpen: false,
            hasActiveChatter: true,
            hasClosedChat: false,
          }),
          subscribeEvent: jest.fn().mockResolvedValue(1),
        }
        ;(window as any).adaEmbed = asyncAdaEmbed

        const {autoRestoreAda} = require('../AdaChatbot')

        autoRestoreAda()
      })

      await waitFor(() => {
        expect((window as any).adaEmbed.start).toHaveBeenCalledTimes(1)
      })

      expect(capturedConfig).toBeDefined()
      expect((window as any).adaEmbed.toggle).not.toHaveBeenCalled()

      // Simulate the Ada SDK invoking the ready callback asynchronously
      await capturedConfig.adaReadyCallback()

      // After ready runs, restore behavior should execute and toggle
      expect((window as any).adaEmbed.toggle).toHaveBeenCalledTimes(1)
    })
  })
})
