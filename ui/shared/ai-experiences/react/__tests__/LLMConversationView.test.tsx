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

    // Default mocks for most tests - can be overridden in individual tests
    // Mock get active conversation (returns empty - no active conversation)
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {})
    // Mock create new conversation
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/conversations', {
      id: '1',
      messages: [],
    })
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
    render(<LLMConversationView {...defaultProps} />)
    expect(screen.getByText('Preview')).toBeInTheDocument()
    expect(screen.getByText('Restart')).toBeInTheDocument()
  })

  it('renders restart button', () => {
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

    // Override default mocks with custom messages
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {}, {overwriteRoutes: true})
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations',
      {id: '1', messages: mockMessages},
      {overwriteRoutes: true},
    )

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

    // Override default mocks with custom messages
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {}, {overwriteRoutes: true})
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations',
      {id: '1', messages: mockMessages},
      {overwriteRoutes: true},
    )

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
    render(<LLMConversationView {...defaultProps} />)

    expect(screen.getByPlaceholderText('Your answer...')).toBeInTheDocument()
    expect(screen.getByText('Send')).toBeInTheDocument()
  })

  it('sends message when send button is clicked', async () => {
    const initialMessages = [
      {role: 'User', text: 'Start', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello', timestamp: new Date()},
    ]

    // Override default mocks with custom messages
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {}, {overwriteRoutes: true})
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations',
      {id: '1', messages: initialMessages},
      {overwriteRoutes: true},
    )

    // Mock post message
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/conversations/1/messages', {
      id: '1',
      messages: [
        ...initialMessages,
        {role: 'User', text: 'Test message', timestamp: new Date()},
        {role: 'Assistant', text: 'Response', timestamp: new Date()},
      ],
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

    // Override default mocks with custom messages
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {}, {overwriteRoutes: true})
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations',
      {id: '1', messages: initialMessages},
      {overwriteRoutes: true},
    )

    // Mock post message with delay
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations/1/messages',
      {
        id: '1',
        messages: [...initialMessages, {role: 'User', text: 'New message', timestamp: new Date()}],
      },
      {delay: 100},
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

    // Override default mocks with custom messages
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {}, {overwriteRoutes: true})
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations',
      {id: '1', messages: mockMessages},
      {overwriteRoutes: true},
    )

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

    // Override default mocks with custom messages
    fetchMock.get('/api/v1/courses/123/ai_experiences/1/conversations', {}, {overwriteRoutes: true})
    fetchMock.post(
      '/api/v1/courses/123/ai_experiences/1/conversations',
      {id: '1', messages: mockMessages},
      {overwriteRoutes: true},
    )

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
      render(<LLMConversationView {...defaultProps} />)

      const liveRegion = document.querySelector('[aria-live="polite"]')
      expect(liveRegion).toBeInTheDocument()
      expect(liveRegion).toHaveAttribute('aria-atomic', 'true')
    })

    it('adds role="log" to messages container', () => {
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

      // Override default mocks with custom messages
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {id: '1', messages: mockMessages},
        {overwriteRoutes: true},
      )

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

      // Override default mocks with custom messages
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {id: '1', messages: mockMessages},
        {overwriteRoutes: true},
      )

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByLabelText('Message from Assistant')).toBeInTheDocument()
        expect(screen.getAllByLabelText('Your message').length).toBeGreaterThan(0)
      })
    })

    it('announces "Initializing conversation..." when initializing', () => {
      // Override with delayed response
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {id: '1', messages: []},
        {delay: 100, overwriteRoutes: true},
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

      // Override default mocks with custom messages
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {id: '1', messages: initialMessages},
        {overwriteRoutes: true},
      )

      // Mock post message with delay
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations/1/messages',
        {
          id: '1',
          messages: [
            ...initialMessages,
            {role: 'User', text: 'Test', timestamp: new Date()},
            {role: 'Assistant', text: 'Response', timestamp: new Date()},
          ],
        },
        {delay: 100},
      )

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

  describe('error handling', () => {
    it('displays error alert when conversation initialization fails', async () => {
      // Override with error response
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {status: 503, body: {error: 'Service unavailable'}},
        {overwriteRoutes: true},
      )

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to start conversation. Please try again.'),
        ).toBeInTheDocument()
      })
    })

    it('displays error alert when sending message fails', async () => {
      const initialMessages = [
        {role: 'User', text: 'Start', timestamp: new Date()},
        {role: 'Assistant', text: 'Hello', timestamp: new Date()},
      ]

      // Override default mocks with custom messages
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {id: '1', messages: initialMessages},
        {overwriteRoutes: true},
      )
      // Mock post message failure
      fetchMock.post('/api/v1/courses/123/ai_experiences/1/conversations/1/messages', {
        status: 503,
        body: {error: 'Failed to send'},
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
        expect(screen.getByText('Failed to send message. Please try again.')).toBeInTheDocument()
      })

      // Optimistically added message should be removed
      expect(screen.queryByText('Test message')).not.toBeInTheDocument()
    })

    it('displays error alert when restart fails', async () => {
      const initialMessages = [
        {role: 'User', text: 'Start', timestamp: new Date()},
        {role: 'Assistant', text: 'Hello', timestamp: new Date()},
      ]

      // Mock get active conversation
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      // Mock create conversation (first call - success)
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {id: '1', messages: initialMessages},
        {repeat: 1, overwriteRoutes: true},
      )
      // Mock create conversation (second call for restart - failure)
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {status: 503, body: {error: 'Failed to restart'}},
        {repeat: 1, overwriteRoutes: false},
      )

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Hello')).toBeInTheDocument()
      })

      const restartButton = screen.getByText('Restart')
      fireEvent.click(restartButton)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to restart conversation. Please try again.'),
        ).toBeInTheDocument()
      })
    })

    it('allows dismissing error alerts', async () => {
      // Override with error response
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {status: 503, body: {error: 'Service unavailable'}},
        {overwriteRoutes: true},
      )

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to start conversation. Please try again.'),
        ).toBeInTheDocument()
      })

      const closeButton = screen.getByText('Close').closest('button')
      fireEvent.click(closeButton!)

      await waitFor(() => {
        expect(
          screen.queryByText('Failed to start conversation. Please try again.'),
        ).not.toBeInTheDocument()
      })
    })

    it('clears error when retrying after failure', async () => {
      // Mock get active conversation
      fetchMock.get(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {},
        {overwriteRoutes: true},
      )
      // Mock create conversation (first call - failure)
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {status: 503, body: {error: 'Failed'}},
        {repeat: 1, overwriteRoutes: true},
      )
      // Mock create conversation (second call - success)
      fetchMock.post(
        '/api/v1/courses/123/ai_experiences/1/conversations',
        {
          id: '1',
          messages: [
            {role: 'User', text: 'Start', timestamp: new Date()},
            {role: 'Assistant', text: 'Hello', timestamp: new Date()},
          ],
        },
        {repeat: 1, overwriteRoutes: false},
      )

      render(<LLMConversationView {...defaultProps} />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to start conversation. Please try again.'),
        ).toBeInTheDocument()
      })

      // Trigger restart which should clear the error
      const restartButton = screen.getByText('Restart')
      fireEvent.click(restartButton)

      await waitFor(() => {
        expect(
          screen.queryByText('Failed to start conversation. Please try again.'),
        ).not.toBeInTheDocument()
        expect(screen.getByText('Hello')).toBeInTheDocument()
      })
    })
  })
})
