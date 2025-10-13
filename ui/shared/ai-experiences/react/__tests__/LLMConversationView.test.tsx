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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import LLMConversationView from '../components/LLMConversationView'

const defaultProps = {
  isOpen: true,
  onClose: jest.fn(),
  courseId: 123,
  aiExperienceId: '1',
  aiExperienceTitle: 'Test Experience',
  facts: 'Test facts',
  learningObjectives: 'Test objectives',
  scenario: 'Test scenario',
  isExpanded: true,
  onToggleExpanded: jest.fn(),
}

describe('LLMConversationView', () => {
  beforeEach(() => {
    fetchMock.restore()
    // Mock scrollIntoView which is not available in JSDOM
    Element.prototype.scrollIntoView = jest.fn()
    // Mock focus which is used for accessibility
    HTMLElement.prototype.focus = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('does not render when closed', () => {
    const {container} = render(<LLMConversationView {...defaultProps} isOpen={false} />)
    expect(container.firstChild).toBeNull()
  })

  it('renders collapsed state when not expanded', () => {
    render(<LLMConversationView {...defaultProps} isExpanded={false} />)
    expect(screen.getByText('Preview')).toBeInTheDocument()
    expect(
      screen.getByText('Here, you can have a chat with the AI just like a student would.'),
    ).toBeInTheDocument()
  })

  it('renders expanded state when expanded', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)
    expect(screen.getByText('Preview')).toBeInTheDocument()
    expect(screen.getByText('Restart')).toBeInTheDocument()
  })

  it('renders restart button', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)
    expect(screen.getByText('Restart')).toBeInTheDocument()
  })

  it('calls onToggleExpanded when collapsed card is clicked', () => {
    const onToggleExpanded = jest.fn()
    render(
      <LLMConversationView
        {...defaultProps}
        isExpanded={false}
        onToggleExpanded={onToggleExpanded}
      />,
    )

    const previewCard = screen.getByText('Preview').closest('[role="button"]')
    fireEvent.click(previewCard!)

    expect(onToggleExpanded).toHaveBeenCalled()
  })

  it('calls onToggleExpanded when close button is clicked', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    const onToggleExpanded = jest.fn()
    render(<LLMConversationView {...defaultProps} onToggleExpanded={onToggleExpanded} />)

    const closeButton = screen.getAllByText('Close preview')[0].closest('button')
    fireEvent.click(closeButton!)

    expect(onToggleExpanded).toHaveBeenCalled()
  })

  it('initializes conversation on mount', async () => {
    const mockMessages = [
      {role: 'User', text: 'Starting prompt', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello! How can I help you?', timestamp: new Date()},
    ]

    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
      messages: mockMessages,
    })

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Hello! How can I help you?')).toBeInTheDocument()
    })
  })

  it('displays messages with correct roles', async () => {
    const mockMessages = [
      {role: 'User', text: 'Starting prompt', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello!', timestamp: new Date()},
      {role: 'User', text: 'Hi there', timestamp: new Date()},
      {role: 'Assistant', text: 'How can I help?', timestamp: new Date()},
    ]

    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
      messages: mockMessages,
    })

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      // First message is hidden (starting prompt)
      expect(screen.queryByText('Starting prompt')).not.toBeInTheDocument()
      // Others are visible
      expect(screen.getByText('Hello!')).toBeInTheDocument()
      expect(screen.getByText('Hi there')).toBeInTheDocument()
      expect(screen.getByText('How can I help?')).toBeInTheDocument()
    })
  })

  it('renders text input and send button', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)

    expect(screen.getByPlaceholderText('Your answer...')).toBeInTheDocument()
    expect(screen.getByText('Send')).toBeInTheDocument()
  })

  it('sends message when send button is clicked', async () => {
    const initialMessages = [
      {role: 'User', text: 'Start', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello', timestamp: new Date()},
    ]

    let callCount = 0
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', () => {
      callCount++
      if (callCount === 1) {
        return {messages: initialMessages}
      }
      return {
        messages: [
          ...initialMessages,
          {role: 'User', text: 'Test message', timestamp: new Date()},
          {role: 'Assistant', text: 'Response', timestamp: new Date()},
        ],
      }
    })

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Hello')).toBeInTheDocument()
    })

    const input = screen.getByPlaceholderText('Your answer...')
    fireEvent.change(input, {target: {value: 'Test message'}})

    const sendButton = screen.getByText('Send')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(screen.getByText('Test message')).toBeInTheDocument()
      expect(screen.getByText('Response')).toBeInTheDocument()
    })
  })

  it('clears input after sending message', async () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)

    const input = screen.getByPlaceholderText('Your answer...') as HTMLTextAreaElement
    fireEvent.change(input, {target: {value: 'Test message'}})

    const sendButton = screen.getByText('Send')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(input.value).toBe('')
    })
  })

  // Note: Button disable behavior during async operations is tested in integration tests

  it('optimistically adds user message before API response', async () => {
    const initialMessages = [
      {role: 'User', text: 'Start', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello', timestamp: new Date()},
    ]

    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/continue_conversation',
      {messages: initialMessages},
      {overwriteRoutes: false},
    )

    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/continue_conversation',
      {messages: [...initialMessages, {role: 'User', text: 'New message', timestamp: new Date()}]},
      {delay: 100, overwriteRoutes: false},
    )

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Hello')).toBeInTheDocument()
    })

    const input = screen.getByPlaceholderText('Your answer...')
    fireEvent.change(input, {target: {value: 'New message'}})

    const sendButton = screen.getByText('Send')
    fireEvent.click(sendButton)

    // Message should appear immediately (optimistic)
    expect(screen.getByText('New message')).toBeInTheDocument()
  })

  // Note: Optimistic message rollback on error is tested in integration tests

  it('restarts conversation when restart button is clicked', async () => {
    const mockMessages = [
      {role: 'User', text: 'Start', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello', timestamp: new Date()},
    ]

    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
      messages: mockMessages,
    })

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Hello')).toBeInTheDocument()
    })

    const restartButton = screen.getByText('Restart')
    fireEvent.click(restartButton)

    // Should re-initialize conversation
    await waitFor(() => {
      expect(fetchMock.calls().length).toBeGreaterThan(1)
    })
  })

  it('does not display sender labels in messages', async () => {
    const mockMessages = [
      {role: 'User', text: 'Start', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello', timestamp: new Date()},
      {role: 'User', text: 'User message', timestamp: new Date()},
    ]

    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
      messages: mockMessages,
    })

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('User message')).toBeInTheDocument()
    })

    // Verify no sender labels are present
    expect(screen.queryByText('You')).not.toBeInTheDocument()
    expect(screen.queryByText('AI Assistant')).not.toBeInTheDocument()
  })

  describe('accessibility features', () => {
    it('renders ARIA live region for screen reader announcements', () => {
      fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

      render(<LLMConversationView {...defaultProps} />)

      const liveRegion = document.querySelector('[aria-live="polite"]')
      expect(liveRegion).toBeInTheDocument()
      expect(liveRegion).toHaveAttribute('aria-atomic', 'true')
    })

    it('adds role="log" to messages container', () => {
      fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

      render(<LLMConversationView {...defaultProps} />)

      const messagesContainer = screen.getByLabelText('Conversation messages')
      expect(messagesContainer).toBeInTheDocument()
      expect(messagesContainer).toHaveAttribute('role', 'log')
    })

    it('adds role="article" to messages', async () => {
      const mockMessages = [
        {role: 'User', text: 'Start', timestamp: new Date()},
        {role: 'Assistant', text: 'Hello', timestamp: new Date()},
        {role: 'User', text: 'Test message', timestamp: new Date()},
      ]

      fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
        messages: mockMessages,
      })

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        const articles = document.querySelectorAll('[role="article"]')
        expect(articles.length).toBeGreaterThan(0)
      })
    })

    it('adds appropriate aria-labels to user and assistant messages', async () => {
      const mockMessages = [
        {role: 'User', text: 'Start', timestamp: new Date()},
        {role: 'Assistant', text: 'Assistant response', timestamp: new Date()},
        {role: 'User', text: 'User message', timestamp: new Date()},
      ]

      fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
        messages: mockMessages,
      })

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByLabelText('Message from Assistant')).toBeInTheDocument()
        expect(screen.getAllByLabelText('Your message').length).toBeGreaterThan(0)
      })
    })

    it('announces "Initializing conversation..." when initializing', () => {
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/continue_conversation',
        {messages: []},
        {delay: 100},
      )

      render(<LLMConversationView {...defaultProps} />)

      const liveRegion = document.querySelector('[aria-live="polite"]')
      expect(liveRegion?.textContent).toContain('Initializing conversation...')
    })

    it('announces "Assistant is thinking..." when loading', async () => {
      const initialMessages = [
        {role: 'User', text: 'Start', timestamp: new Date()},
        {role: 'Assistant', text: 'Hello', timestamp: new Date()},
      ]

      let callCount = 0
      fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', () => {
        callCount++
        if (callCount === 1) {
          return {messages: initialMessages}
        }
        return new Promise(resolve =>
          setTimeout(
            () =>
              resolve({
                messages: [
                  ...initialMessages,
                  {role: 'User', text: 'Test', timestamp: new Date()},
                  {role: 'Assistant', text: 'Response', timestamp: new Date()},
                ],
              }),
            100,
          ),
        )
      })

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Hello')).toBeInTheDocument()
      })

      const input = screen.getByPlaceholderText('Your answer...')
      fireEvent.change(input, {target: {value: 'Test'}})

      const sendButton = screen.getByText('Send')
      fireEvent.click(sendButton)

      // Check that the announcement is made
      await waitFor(() => {
        const liveRegion = document.querySelector('[aria-live="polite"]')
        expect(liveRegion?.textContent).toContain('Assistant is thinking...')
      })
    })
  })
})
