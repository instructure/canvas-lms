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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import StudyAssistTray from '../StudyAssistTray'
import * as PendoModule from '@canvas/pendo'

const mockAssistContent = vi.fn((_props: object) => <div data-testid="assist-content" />)
const mockAssistFlashCardsInteraction = vi.fn((_props: object) => <div />)
const mockResetChat = vi.fn()
const mockUseAssistContext = vi.fn(() => ({showBackButton: false, resetChat: mockResetChat}))
const mockTrack = vi.fn()

vi.mock('@canvas/ai-information', () => ({
  default: ({triggerButton}: {triggerButton: React.ReactNode}) => (
    <div data-testid="ai-information">{triggerButton}</div>
  ),
}))

vi.mock('@instructure/platform-study-assist', () => ({
  AssistProvider: ({
    children,
    pageId,
    fileId,
    featureSlug,
  }: {
    children: React.ReactNode
    pageId?: string
    fileId?: string
    featureSlug?: string
  }) => (
    <div
      data-testid="assist-provider"
      data-page-id={pageId}
      data-file-id={fileId}
      data-feature-slug={featureSlug}
    >
      {children}
    </div>
  ),
  AssistContent: (props: object) => mockAssistContent(props),
  AssistFlashCardsInteraction: (props: object) => mockAssistFlashCardsInteraction(props),
  useAssistContext: () => mockUseAssistContext(),
}))

describe('StudyAssistTray', () => {
  const onDismiss = vi.fn()
  const fetchAssistResponse = vi.fn()

  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      COURSE_ID: '123',
      WIKI_PAGE_ID: 'test-page',
      STUDY_ASSIST_TOOLS: ['Summarize', 'Quiz me', 'Flashcards'],
    } as any
    vi.spyOn(PendoModule, 'initializePendo').mockResolvedValue({track: mockTrack})
    onDismiss.mockReset()
    mockAssistContent.mockClear()
    mockAssistFlashCardsInteraction.mockClear()
    mockTrack.mockClear()
    mockResetChat.mockReset()
    mockUseAssistContext.mockReturnValue({showBackButton: false, resetChat: mockResetChat})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renders the AI information button', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByTestId('study-assist-ai-info-button')).toBeInTheDocument()
  })

  it('renders the heading when open', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByText('Study tools')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', async () => {
    const user = userEvent.setup()
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    const closeEl = screen.getByTestId('study-assist-close-button')
    const button = closeEl.tagName === 'BUTTON' ? closeEl : closeEl.querySelector('button')
    await user.click(button!)
    expect(onDismiss).toHaveBeenCalledTimes(1)
  })

  it('passes WIKI_PAGE_ID as pageId to AssistProvider', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByTestId('assist-provider')).toHaveAttribute('data-page-id', 'test-page')
  })

  it('passes featureSlug="canvas-lms:study-assist" to AssistProvider', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByTestId('assist-provider')).toHaveAttribute(
      'data-feature-slug',
      'canvas-lms:study-assist',
    )
  })

  it('configures AssistContent for prompts-only mode with filtered prompts', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(mockAssistContent).toHaveBeenCalledWith(
      expect.objectContaining({
        chatEnabled: false,
        showLargePrompts: true,
        allowedPrompts: ['Summarize', 'Quiz me', 'Flashcards'],
      }),
    )
  })

  it('passes only enabled tools from STUDY_ASSIST_TOOLS', () => {
    window.ENV = {
      ...window.ENV,
      STUDY_ASSIST_TOOLS: ['Summarize', 'Flashcards'],
    } as any
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(mockAssistContent).toHaveBeenCalledWith(
      expect.objectContaining({
        allowedPrompts: ['Summarize', 'Flashcards'],
      }),
    )
  })

  it('shows empty state when no tools are enabled', () => {
    window.ENV = {
      ...window.ENV,
      STUDY_ASSIST_TOOLS: [],
    } as any
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByTestId('study-assist-no-tools')).toBeInTheDocument()
    expect(screen.getByText('No study tools are currently available.')).toBeInTheDocument()
    expect(mockAssistContent).not.toHaveBeenCalled()
  })

  it('shows empty state when STUDY_ASSIST_TOOLS is undefined', () => {
    window.ENV = {
      ...window.ENV,
      STUDY_ASSIST_TOOLS: undefined,
    } as any
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByTestId('study-assist-no-tools')).toBeInTheDocument()
    expect(mockAssistContent).not.toHaveBeenCalled()
  })

  it('renderFlashCards renders AssistFlashCardsInteraction with cardHeight', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    const {renderFlashCards} = mockAssistContent.mock.calls[0][0] as {
      renderFlashCards: (
        cards: object[],
        isFetching: boolean,
        isError: boolean,
        getFlashCards: () => void,
      ) => React.ReactNode
    }
    const mockCards = [{question: 'Q', answer: 'A'}]
    render(<>{renderFlashCards(mockCards, false, false, vi.fn())}</>)

    expect(mockAssistFlashCardsInteraction).toHaveBeenCalledWith(
      expect.objectContaining({
        cardData: mockCards,
        isFetching: false,
        isError: false,
        cardHeight: '60vh',
      }),
    )
  })

  it('renderFlashCards forwards onAnalyticsEvent so flashcard thumbs fire Pendo events', async () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    const {renderFlashCards} = mockAssistContent.mock.calls[0][0] as {
      renderFlashCards: (
        cards: object[],
        isFetching: boolean,
        isError: boolean,
        getFlashCards: () => void,
      ) => React.ReactNode
    }
    render(<>{renderFlashCards([{question: 'Q', answer: 'A'}], false, false, vi.fn())}</>)

    const flashCardsProps = mockAssistFlashCardsInteraction.mock.calls[0][0] as {
      onAnalyticsEvent?: (event: string) => void
    }
    expect(typeof flashCardsProps.onAnalyticsEvent).toBe('function')

    flashCardsProps.onAnalyticsEvent?.('chat-good-response')
    await vi.waitFor(() => {
      expect(mockTrack).toHaveBeenCalledWith('study_assist_chat-good-response', {type: 'track'})
    })
  })

  describe('analytics events', () => {
    it('passes handleAnalyticsEvent to AssistContent', () => {
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      const {onAnalyticsEvent} = mockAssistContent.mock.calls[0][0] as {
        onAnalyticsEvent: (event: string) => void
      }
      expect(typeof onAnalyticsEvent).toBe('function')
    })

    it('tracks thumbs up event with correct Pendo event name', async () => {
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      const {onAnalyticsEvent} = mockAssistContent.mock.calls[0][0] as {
        onAnalyticsEvent: (event: string) => void
      }
      onAnalyticsEvent('chat-good-response')
      await vi.waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('study_assist_chat-good-response', {type: 'track'})
      })
    })

    it('tracks thumbs down event with correct Pendo event name', async () => {
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      const {onAnalyticsEvent} = mockAssistContent.mock.calls[0][0] as {
        onAnalyticsEvent: (event: string) => void
      }
      onAnalyticsEvent('chat-bad-response')
      await vi.waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('study_assist_chat-bad-response', {type: 'track'})
      })
    })

    it('tracks prompt click events with correct Pendo event name', async () => {
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      const {onAnalyticsEvent} = mockAssistContent.mock.calls[0][0] as {
        onAnalyticsEvent: (event: string) => void
      }
      onAnalyticsEvent('prompt-summarize')
      await vi.waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('study_assist_prompt-summarize', {type: 'track'})
      })
    })

    it('tracks citation link click events with correct Pendo event name', async () => {
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      const {onAnalyticsEvent} = mockAssistContent.mock.calls[0][0] as {
        onAnalyticsEvent: (event: string) => void
      }
      onAnalyticsEvent('citation-link-page')
      await vi.waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('study_assist_citation-link-page', {type: 'track'})
      })
    })
  })

  describe('back button', () => {
    it('is not visible when showBackButton is false', () => {
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      expect(screen.queryByTestId('study-assist-back-button')).not.toBeInTheDocument()
    })

    it('is visible when showBackButton is true', () => {
      mockUseAssistContext.mockReturnValue({showBackButton: true, resetChat: mockResetChat})
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      expect(screen.getByTestId('study-assist-back-button')).toBeInTheDocument()
    })

    it('calls resetChat when clicked', async () => {
      const user = userEvent.setup()
      mockUseAssistContext.mockReturnValue({showBackButton: true, resetChat: mockResetChat})
      render(
        <StudyAssistTray
          open={true}
          onDismiss={onDismiss}
          fetchAssistResponse={fetchAssistResponse}
        />,
      )
      const backEl = screen.getByTestId('study-assist-back-button')
      const button = backEl.tagName === 'BUTTON' ? backEl : backEl.querySelector('button')
      await user.click(button!)
      expect(mockResetChat).toHaveBeenCalledTimes(1)
    })
  })
})
