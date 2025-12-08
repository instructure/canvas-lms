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

import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'
import {render, cleanup, waitFor} from '@testing-library/react'
import AdaChatbot, {autoRestoreAda} from '../AdaChatbot'

const ADA_STATE_KEY = 'persistedAdaState'

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
    fakeENV.setup({
      ADA_CHATBOT_ENABLED: true,
      current_user: {},
      current_user_roles: [],
      DOMAIN_ROOT_ACCOUNT_UUID: 'test-uuid',
    })
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
    fakeENV.teardown()
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
    expect(localStorage.getItem(ADA_STATE_KEY)).toBe('open')
  })

  it('does not mark chat closed when drawer is closed via toggleCallback', async () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    await getStartConfig().adaReadyCallback()

    getStartConfig().toggleCallback(false)
    expect(localStorage.getItem(ADA_STATE_KEY)).toBe('minimized')
  })

  it('opens Ada via help menu regardless of previous state', async () => {
    localStorage.setItem(ADA_STATE_KEY, 'closed') // Previously closed

    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    await getStartConfig().adaReadyCallback()
    await waitFor(() => expect(mockAdaEmbed.toggle).toHaveBeenCalled()) // Should open regardless
    expect(localStorage.getItem(ADA_STATE_KEY)).toBe('open') // Now open
  })

  it('does not toggle when chat is already open via help menu', async () => {
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

  it('handles errors during Ada opening gracefully', async () => {
    mockAdaEmbed.getInfo.mockRejectedValueOnce(new Error('getInfo failed'))
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

    await getStartConfig().adaReadyCallback()
    await waitFor(() =>
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to open Ada chatbot:',
        expect.any(Error),
      ),
    )
  })

  it('handles initialization errors gracefully', async () => {
    mockAdaEmbed.start.mockRejectedValue(new Error('Ada initialization failed'))
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    await waitFor(() =>
      expect(consoleWarnSpy).toHaveBeenCalledWith('Ada start failed:', expect.any(Error)),
    )
    expect(mockOnDialogClose).toHaveBeenCalled()
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

    expect(localStorage.getItem(ADA_STATE_KEY)).toBe('closed')
    await waitFor(() => expect(mockAdaEmbed.stop).toHaveBeenCalled())
  })

  it.each(['ada:minimize_chat', 'ada:close_chat'])(
    'keeps chat active on %s event',
    async eventName => {
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
      await getStartConfig().adaReadyCallback()

      getStartConfig().onAdaEmbedLoaded()
      getEventCallback(eventName)()

      expect(localStorage.getItem(ADA_STATE_KEY)).toBe('minimized')
    },
  )

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
      localStorage.setItem(ADA_STATE_KEY, 'open')
      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
    })

    it('does not initialize when closed by user', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'closed')
      autoRestoreAda()
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(mockAdaEmbed.start).not.toHaveBeenCalled()
    })

    it('prevents duplicate initialization and concurrent restore operations', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')

      autoRestoreAda()
      autoRestoreAda()
      autoRestoreAda()

      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalledTimes(1))
      await getStartConfig().adaReadyCallback()

      await waitFor(() => expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1))
    })

    it('allows reinitialization after stop()', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')

      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      await resetInitialized()

      localStorage.setItem(ADA_STATE_KEY, 'open')
      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalledTimes(2))
    })

    it('handles initialization errors gracefully', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')
      mockAdaEmbed.start.mockRejectedValue(new Error('Init failed'))
      autoRestoreAda()
      await waitFor(() =>
        expect(consoleWarnSpy).toHaveBeenCalledWith('Ada start failed:', expect.any(Error)),
      )
    })

    it('restores drawer when previously open', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')

      mockAdaEmbed.getInfo
        .mockResolvedValueOnce({
          isChatOpen: false,
          isDrawerOpen: false,
          hasActiveChatter: false,
          hasClosedChat: false,
        })
        .mockResolvedValueOnce({
          isChatOpen: true,
          isDrawerOpen: true,
          hasActiveChatter: false,
          hasClosedChat: false,
        })

      const restorePromise = autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      // Trigger adaReadyCallback to complete initialization
      await getStartConfig().adaReadyCallback()
      await restorePromise

      expect(mockAdaEmbed.toggle).toHaveBeenCalled()
      expect(localStorage.getItem(ADA_STATE_KEY)).toBe('open')
    })

    it('does not restore drawer if drawer was not previously open', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'minimized')

      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      await getStartConfig().adaReadyCallback()
      await new Promise(resolve => setTimeout(resolve, 50))

      expect(mockAdaEmbed.toggle).not.toHaveBeenCalled()
    })

    it('handles errors during drawer restoration gracefully', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')
      mockAdaEmbed.toggle.mockRejectedValue(new Error('Toggle failed'))

      autoRestoreAda()
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      await getStartConfig().adaReadyCallback()
      await waitFor(() =>
        expect(consoleWarnSpy).toHaveBeenCalledWith('Auto-restore Ada failed:', expect.any(Error)),
      )
    })
  })

  describe('race condition prevention', () => {
    it('prevents concurrent openAda calls', async () => {
      // Render two components at the same time
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
      await getStartConfig().adaReadyCallback()
      await waitFor(() => expect(mockAdaEmbed.toggle).toHaveBeenCalled())

      // Only one toggle despite two components
      expect(mockAdaEmbed.toggle).toHaveBeenCalledTimes(1)
      expect(mockOnDialogClose).toHaveBeenCalledTimes(2)
      expect(consoleWarnSpy).toHaveBeenCalledWith('Ada is already being opened')
    })

    it('prevents openAda during autoRestoreAda', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')

      // Make start() take longer to ensure the flag stays set
      let resolveStart: () => void
      const startPromise = new Promise<void>(resolve => {
        resolveStart = resolve
      })
      mockAdaEmbed.start.mockReturnValue(startPromise)

      // Start autoRestoreAda (without awaiting)
      const restorePromise = autoRestoreAda()

      // Wait for start to be called (flag is now set)
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

      // Should warn about concurrent operation
      await waitFor(() =>
        expect(consoleWarnSpy).toHaveBeenCalledWith('Ada is already being opened'),
      )

      resolveStart!()
      await getStartConfig().adaReadyCallback()
      await restorePromise
    })

    it('resets state flags when Ada is stopped', async () => {
      localStorage.setItem(ADA_STATE_KEY, 'open')

      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())

      getStartConfig().onAdaEmbedLoaded()
      getEventCallback('ada:end_conversation')()

      await waitFor(() => expect(mockAdaEmbed.stop).toHaveBeenCalled())

      cleanup()
      mockAdaEmbed.start.mockClear()
      mockAdaEmbed.toggle.mockClear()

      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
      await waitFor(() => expect(mockAdaEmbed.start).toHaveBeenCalled())
      expect(consoleWarnSpy).not.toHaveBeenCalledWith('Ada is already being opened')
    })
  })
})
