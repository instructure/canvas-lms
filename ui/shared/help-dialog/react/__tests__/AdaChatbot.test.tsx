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
import AdaChatbot, {autoRestoreAda} from '../AdaChatbot'

const CHAT_CLOSED_KEY = 'persistedAdaClosed'
const DRAWER_OPEN_KEY = 'persistedAdaDrawerOpen'

describe('AdaChatbot', () => {
  const mockOnDialogClose = jest.fn()
  let mockAdaEmbed: any
  let consoleWarnSpy: jest.SpyInstance
  let consoleErrorSpy: jest.SpyInstance

  // Helper to extract callbacks from Ada start configuration
  const getStartConfig = () => mockAdaEmbed.start.mock.calls[0][0]
  const getEventCallback = (eventName: string) =>
    mockAdaEmbed.subscribeEvent.mock.calls.find(([key]: [string]) => key === eventName)?.[1]

  // Helper to reset isInitialized flag by triggering end_conversation
  const resetInitialized = async () => {
    if (mockAdaEmbed.start.mock.calls.length > 0) {
      getStartConfig().onAdaEmbedLoaded()
      getEventCallback('ada:end_conversation')()
      await waitFor(() => expect(mockAdaEmbed.stop).toHaveBeenCalled())
    }
  }

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
      stop: jest.fn().mockResolvedValue(undefined),
    }
    ;(window as any).adaEmbed = mockAdaEmbed
  })

  afterEach(async () => {
    if (mockAdaEmbed?.start?.mock?.calls?.length > 0) {
      await resetInitialized().catch(() => {})
    }
    cleanup()
    localStorage.clear()
    jest.restoreAllMocks()
  })

  it('renders nothing and calls onDialogClose', async () => {
    const {container} = render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    expect(container.firstChild).toBeNull()
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()
    await waitFor(() => expect(mockOnDialogClose).toHaveBeenCalled())
  })

  it('handles missing Ada embed gracefully', async () => {
    delete (window as any).adaEmbed
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockOnDialogClose).toHaveBeenCalled())
  })

  it('initializes Ada with correct configuration', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    const config = getStartConfig()
    expect(config.handle).toBe('instructure-gen')
    expect(config).toHaveProperty('onAdaEmbedLoaded')
    expect(config).toHaveProperty('adaReadyCallback')
    expect(config).toHaveProperty('toggleCallback')
  })

  it('merges global adaSettings and overrides handle', async () => {
    const globalSettings = {
      crossWindowPersistence: true,
      metaFields: {email: 'user@example.com'},
      handle: 'should-be-overridden',
    }
    ;(window as any).adaSettings = globalSettings

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    const config = getStartConfig()
    expect(config.metaFields).toEqual(globalSettings.metaFields)
    expect(config.crossWindowPersistence).toBe(true)
    expect(config.handle).toBe('instructure-gen')
  })

  it('toggles Ada when chat is closed', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()
    await waitFor(() => expect(mockAdaEmbed.toggle).toHaveBeenCalled())
  })

  it('does not toggle when chat is already open', async () => {
    mockAdaEmbed.getInfo.mockResolvedValue({
      isChatOpen: true,
      isDrawerOpen: true,
      hasActiveChatter: false,
      hasClosedChat: false,
    })
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
  })

  it('marks chat as active and drawer open when opened', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()
    await waitFor(() => expect(mockAdaEmbed.toggle).toHaveBeenCalled())
    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('true')
  })

  it('does not mark chat closed when drawer is closed via toggleCallback', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()

    getStartConfig().toggleCallback(false)
    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
  })

  it('restores drawer when previously open and not closed by user', async () => {
    localStorage.setItem(DRAWER_OPEN_KEY, 'true')
    mockAdaEmbed.getInfo.mockResolvedValue({
      isChatOpen: false,
      isDrawerOpen: false,
      hasActiveChatter: true,
      hasClosedChat: false,
    })

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    await getStartConfig().adaReadyCallback()
    expect(mockAdaEmbed.toggle).toHaveBeenCalled()
  })

  it('restores drawer in adaReadyCallback when opened via help menu', async () => {
    localStorage.setItem(CHAT_CLOSED_KEY, 'true') // Previously closed
    localStorage.setItem(DRAWER_OPEN_KEY, 'true') // Drawer was open

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    // openAda marks chat as active, so adaReadyCallback should restore drawer
    mockAdaEmbed.toggle.mockClear()
    await getStartConfig().adaReadyCallback()
    expect(mockAdaEmbed.toggle).toHaveBeenCalled() // Should restore drawer
  })

  it('does not restore drawer when chat is already open', async () => {
    localStorage.setItem(DRAWER_OPEN_KEY, 'true')
    mockAdaEmbed.getInfo.mockResolvedValue({
      isChatOpen: true,
      isDrawerOpen: true,
      hasActiveChatter: false,
      hasClosedChat: false,
    })

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    await getStartConfig().adaReadyCallback()
    expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
  })

  it('handles errors in adaReadyCallback gracefully', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    mockAdaEmbed.getInfo.mockRejectedValueOnce(new Error('getInfo failed'))
    await getStartConfig().adaReadyCallback()
    expect(consoleWarnSpy).toHaveBeenCalledWith('Ada ready callback failed:', expect.any(Error))
  })

  it('handles initialization errors gracefully', async () => {
    mockAdaEmbed.start.mockRejectedValue(new Error('Ada initialization failed'))
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() =>
      expect(consoleWarnSpy).toHaveBeenCalledWith('Ada start failed:', expect.any(Error)),
    )
    expect(mockOnDialogClose).toHaveBeenCalled()
  })

  it('prevents duplicate initialization', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1))
  })

  it('handles operation errors gracefully', async () => {
    mockAdaEmbed.toggle.mockRejectedValue(new Error('Toggle failed'))
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()
    await waitFor(() =>
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to open Ada chatbot:',
        expect.any(Error),
      ),
    )
    expect(mockOnDialogClose).toHaveBeenCalled()
  })

  it('marks chat closed on end_conversation event and calls stop()', async () => {
    mockAdaEmbed.stop = jest.fn().mockResolvedValue(undefined)
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    getStartConfig().onAdaEmbedLoaded()
    getEventCallback('ada:end_conversation')()

    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('true')
    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
    await waitFor(() => expect(mockAdaEmbed.stop).toHaveBeenCalled())
  })

  it('keeps chat active on minimize_chat event', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()

    getStartConfig().onAdaEmbedLoaded()
    getEventCallback('ada:minimize_chat')()

    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
  })

  it('keeps chat active on close_chat event', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()

    getStartConfig().onAdaEmbedLoaded()
    getEventCallback('ada:close_chat')()

    expect(localStorage.getItem(DRAWER_OPEN_KEY)).toBe('false')
    expect(localStorage.getItem(CHAT_CLOSED_KEY)).toBe('false')
  })

  it('allows reinitialization when stop() fails', async () => {
    mockAdaEmbed.stop = jest.fn().mockRejectedValue(new Error('Stop failed'))
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    await resetInitialized().catch(() => {}) // Triggers stop which fails but resets flag

    await waitFor(() =>
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'Ada stop failed on end_conversation:',
        expect.any(Error),
      ),
    )

    cleanup()
    mockAdaEmbed.start.mockClear()
    mockAdaEmbed.stop.mockResolvedValue(undefined)
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
  })

  describe('autoRestoreAda', () => {
    it('initializes Ada when not closed by user', async () => {
      localStorage.setItem(CHAT_CLOSED_KEY, 'false')
      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    })

    it('does not initialize when closed by user', async () => {
      localStorage.setItem(CHAT_CLOSED_KEY, 'true')
      autoRestoreAda()
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(mockAdaEmbed.start).not.toHaveBeenCalled()
    })

    it('prevents duplicate initialization', async () => {
      localStorage.setItem(CHAT_CLOSED_KEY, 'false')
      autoRestoreAda()
      autoRestoreAda()
      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1))
    })

    it('allows reinitialization after stop()', async () => {
      localStorage.setItem(CHAT_CLOSED_KEY, 'false')

      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      await resetInitialized()

      localStorage.setItem(CHAT_CLOSED_KEY, 'false')
      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalledTimes(2))
    })

    it('handles initialization errors gracefully', async () => {
      localStorage.setItem(CHAT_CLOSED_KEY, 'false')
      mockAdaEmbed.start.mockRejectedValue(new Error('Init failed'))
      autoRestoreAda()
      await waitFor(() =>
        expect(consoleWarnSpy).toHaveBeenCalledWith('Ada start failed:', expect.any(Error)),
      )
    })

    it('restores drawer via adaReadyCallback when previously open', async () => {
      localStorage.setItem(DRAWER_OPEN_KEY, 'true')
      localStorage.setItem(CHAT_CLOSED_KEY, 'false')

      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
      expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()

      await getStartConfig().adaReadyCallback()
      expect(mockAdaEmbed.toggle).toHaveBeenCalled()
    })
  })
})
