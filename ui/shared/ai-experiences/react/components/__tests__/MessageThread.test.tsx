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

import '@instructure/canvas-theme'
import React from 'react'
import {render, screen} from '@testing-library/react'
import {setupServer} from 'msw/node'
import MessageThread from '../MessageThread'
import type {LLMConversationMessage} from '../../../types'

// MessageFeedback makes API calls — provide a server to handle them
const server = setupServer()
beforeAll(() => server.listen({onUnhandledRequest: 'warn'}))
afterAll(() => server.close())
afterEach(() => server.resetHandlers())

const systemMessage: LLMConversationMessage = {
  role: 'Assistant',
  text: 'System prompt',
}

const assistantMessage = (
  overrides: Partial<LLMConversationMessage> = {},
): LLMConversationMessage => ({
  role: 'Assistant',
  text: 'Hello, how can I help?',
  id: 'msg-1',
  feedback: [],
  ...overrides,
})

const userMessage = (overrides: Partial<LLMConversationMessage> = {}): LLMConversationMessage => ({
  role: 'User',
  text: 'I need help with this topic.',
  ...overrides,
})

const defaultProps = {
  conversationId: 'conv-1',
  courseId: 123,
  aiExperienceId: '1',
}

describe('MessageThread', () => {
  it('renders assistant and user messages', () => {
    render(
      <MessageThread
        {...defaultProps}
        messages={[systemMessage, assistantMessage(), userMessage()]}
      />,
    )

    expect(screen.getByTestId('llm-conversation-message-Assistant')).toBeInTheDocument()
    expect(screen.getByTestId('llm-conversation-message-User')).toBeInTheDocument()
  })

  it('skips the first message (system prompt)', () => {
    render(
      <MessageThread
        {...defaultProps}
        messages={[systemMessage, assistantMessage({text: 'Visible message'})]}
      />,
    )

    expect(screen.queryByText('System prompt')).not.toBeInTheDocument()
    expect(screen.getByText('Visible message')).toBeInTheDocument()
  })

  it('renders nothing when only the system message is present', () => {
    const {container} = render(<MessageThread {...defaultProps} messages={[systemMessage]} />)

    expect(container.querySelector('[data-testid^="llm-conversation-message-"]')).toBeNull()
  })

  describe('MessageFeedback', () => {
    it('shows feedback buttons for assistant messages with id and conversationId', () => {
      render(
        <MessageThread
          {...defaultProps}
          messages={[systemMessage, assistantMessage({id: 'msg-1'})]}
        />,
      )

      expect(screen.getByTestId('message-feedback-like')).toBeInTheDocument()
      expect(screen.getByTestId('message-feedback-dislike')).toBeInTheDocument()
    })

    it('does not show feedback for user messages', () => {
      render(<MessageThread {...defaultProps} messages={[systemMessage, userMessage()]} />)

      expect(screen.queryByTestId('message-feedback-like')).not.toBeInTheDocument()
    })

    it('does not show feedback when assistant message has no id', () => {
      render(
        <MessageThread
          {...defaultProps}
          messages={[systemMessage, assistantMessage({id: undefined})]}
        />,
      )

      expect(screen.queryByTestId('message-feedback-like')).not.toBeInTheDocument()
    })

    it('does not show feedback when conversationId is null', () => {
      render(
        <MessageThread
          {...defaultProps}
          conversationId={null}
          messages={[systemMessage, assistantMessage({id: 'msg-1'})]}
        />,
      )

      expect(screen.queryByTestId('message-feedback-like')).not.toBeInTheDocument()
    })
  })

  describe('loading states', () => {
    it('shows thinking spinner when isLoading', () => {
      render(
        <MessageThread
          {...defaultProps}
          messages={[systemMessage, userMessage()]}
          isLoading={true}
        />,
      )

      expect(screen.getByTitle('Thinking...')).toBeInTheDocument()
    })

    it('does not show messages when isInitializing', () => {
      render(
        <MessageThread
          {...defaultProps}
          messages={[systemMessage, assistantMessage()]}
          isInitializing={true}
        />,
      )

      expect(screen.queryByTestId('llm-conversation-message-Assistant')).not.toBeInTheDocument()
      expect(screen.getByTitle('Initializing conversation...')).toBeInTheDocument()
    })
  })
})
