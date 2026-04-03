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

const mockAssistContent = vi.fn((_props: object) => <div data-testid="assist-content" />)
const mockAssistFlashCardsInteraction = vi.fn((_props: object) => <div />)

vi.mock('@canvas/instui-bindings/react/AiInformation', () => ({
  default: ({triggerButton}: {triggerButton: React.ReactNode}) => (
    <div data-testid="ai-information">{triggerButton}</div>
  ),
}))

vi.mock('@instructure/platform-study-assist', () => ({
  AssistProvider: ({
    children,
    pageId,
    fileId,
  }: {
    children: React.ReactNode
    pageId?: string
    fileId?: string
  }) => (
    <div data-testid="assist-provider" data-page-id={pageId} data-file-id={fileId}>
      {children}
    </div>
  ),
  AssistContent: (props: object) => mockAssistContent(props),
  AssistFlashCardsInteraction: (props: object) => mockAssistFlashCardsInteraction(props),
}))

describe('StudyAssistTray', () => {
  const onDismiss = vi.fn()
  const fetchAssistResponse = vi.fn()

  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      COURSE_ID: '123',
      WIKI_PAGE_ID: 'test-page',
    } as any
    onDismiss.mockReset()
    mockAssistContent.mockClear()
    mockAssistFlashCardsInteraction.mockClear()
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
})
