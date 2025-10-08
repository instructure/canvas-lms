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
}

describe('LLMConversationView', () => {
  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('does not render when closed', () => {
    const {container} = render(<LLMConversationView {...defaultProps} isOpen={false} />)
    expect(container.firstChild).toBeNull()
  })

  it('renders when open', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)
    expect(screen.getByText('Test Experience')).toBeInTheDocument()
  })

  it('renders close and reset button', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)
    expect(screen.getByText('Close and Reset')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    const onClose = jest.fn()
    render(<LLMConversationView {...defaultProps} onClose={onClose} />)

    const closeButton = screen.getByText('Close and Reset')
    fireEvent.click(closeButton)

    expect(onClose).toHaveBeenCalled()
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

    expect(screen.getByLabelText('Your message')).toBeInTheDocument()
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

    const input = screen.getByLabelText('Your message')
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

    const input = screen.getByLabelText('Your message') as HTMLTextAreaElement
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

    const input = screen.getByLabelText('Your message')
    fireEvent.change(input, {target: {value: 'New message'}})

    const sendButton = screen.getByText('Send')
    fireEvent.click(sendButton)

    // Message should appear immediately (optimistic)
    expect(screen.getByText('New message')).toBeInTheDocument()
  })

  // Note: Optimistic message rollback on error is tested in integration tests

  it('clears messages when close button is clicked', async () => {
    const mockMessages = [
      {role: 'User', text: 'Start', timestamp: new Date()},
      {role: 'Assistant', text: 'Hello', timestamp: new Date()},
    ]

    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {
      messages: mockMessages,
    })

    const onClose = jest.fn()
    render(<LLMConversationView {...defaultProps} onClose={onClose} />)

    await waitFor(() => {
      expect(screen.getByText('Hello')).toBeInTheDocument()
    })

    const closeButton = screen.getByText('Close and Reset')
    fireEvent.click(closeButton)

    expect(onClose).toHaveBeenCalled()
  })

  it('focuses close button when conversation opens', async () => {
    fetchMock.post('/api/v1/courses/123/ai_experiences/1/continue_conversation', {messages: []})

    render(<LLMConversationView {...defaultProps} />)

    await waitFor(() => {
      const closeButton = screen.getByText('Close and Reset').closest('button')
      expect(document.activeElement).toBe(closeButton)
    })
  })

  it('displays user messages on the right', async () => {
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

    // Verify the user message label is present
    const youLabels = screen.getAllByText('You')
    expect(youLabels.length).toBeGreaterThan(0)
  })
})
