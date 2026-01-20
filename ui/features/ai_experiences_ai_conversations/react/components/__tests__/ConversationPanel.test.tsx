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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import ConversationPanel from '../ConversationPanel'

describe('ConversationPanel', () => {
  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('shows empty state when no conversation is selected', () => {
    render(<ConversationPanel conversationId={undefined} courseId="123" aiExperienceId="1" />)

    expect(screen.getByText(/Select a student to view their conversation/i)).toBeInTheDocument()
  })

  it('displays conversation messages', async () => {
    const mockConversation = {
      id: 'conv-1',
      user_id: '10',
      llm_conversation_id: 'llm-1',
      workflow_state: 'active',
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-20T00:00:00Z',
      student: {
        id: '10',
        name: 'John Doe',
      },
      messages: [
        {role: 'user', content: 'Trigger message'},
        {role: 'assistant', content: 'Hello! How can I help you?'},
        {role: 'user', content: 'I have a question about history.'},
        {role: 'assistant', content: 'Sure, what would you like to know?'},
      ],
      progress: {status: 'in_progress'},
    }

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      mockConversation,
    )

    render(<ConversationPanel conversationId="conv-1" courseId="123" aiExperienceId="1" />)

    await waitFor(() => {
      expect(screen.getByText('Hello! How can I help you?')).toBeInTheDocument()
      expect(screen.getByText('I have a question about history.')).toBeInTheDocument()
      expect(screen.getByText('Sure, what would you like to know?')).toBeInTheDocument()
      // Trigger message should not be displayed
      expect(screen.queryByText('Trigger message')).not.toBeInTheDocument()
    })
  })

  it('shows loading state while fetching conversation', () => {
    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      new Promise(() => {}), // Never resolves
      {delay: 100},
    )

    render(<ConversationPanel conversationId="conv-1" courseId="123" aiExperienceId="1" />)

    expect(screen.getByText(/Loading conversation/i)).toBeInTheDocument()
  })

  it('switches between Conversation and AI analysis tabs', async () => {
    const mockConversation = {
      id: 'conv-1',
      messages: [
        {role: 'user', content: 'Trigger'},
        {role: 'assistant', content: 'Hello!'},
      ],
      progress: {status: 'completed'},
    }

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      mockConversation,
    )

    render(<ConversationPanel conversationId="conv-1" courseId="123" aiExperienceId="1" />)

    await waitFor(() => {
      expect(screen.getByText('Hello!')).toBeInTheDocument()
    })

    // Click on AI analysis tab
    const aiAnalysisTab = screen.getByText('AI analysis')
    await userEvent.click(aiAnalysisTab)

    expect(screen.getByText(/AI analysis coming soon/i)).toBeInTheDocument()
  })

  it('shows error state when API call fails', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1', 500)

    render(<ConversationPanel conversationId="conv-1" courseId="123" aiExperienceId="1" />)

    await waitFor(() => {
      expect(screen.getByText(/Error loading conversation/i)).toBeInTheDocument()
    })
  })

  it('renders Cancel and Grade buttons in footer', async () => {
    const mockConversation = {
      id: 'conv-1',
      messages: [],
      progress: null,
    }

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      mockConversation,
    )

    render(<ConversationPanel conversationId="conv-1" courseId="123" aiExperienceId="1" />)

    await waitFor(() => {
      expect(screen.getByText('Cancel')).toBeInTheDocument()
      expect(screen.getByText('Grade')).toBeInTheDocument()
    })
  })
})
