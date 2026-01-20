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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import AIConversationsPage from '../AIConversationsPage'
import type {AIExperience} from '../../../types'

const server = setupServer()

const mockAiExperience: AIExperience = {
  id: '1',
  title: 'Test Experience',
  description: 'Test description',
  course_id: '123',
  facts: 'Test facts',
  learning_objective: 'Test objectives',
  pedagogical_guidance: 'Test guidance',
  can_manage: true,
}

const mockConversations = [
  {
    id: 'conv1',
    user_id: 'student1',
    llm_conversation_id: 'llm1',
    workflow_state: 'active',
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T01:00:00Z',
    has_conversation: true,
    student: {
      id: 'student1',
      name: 'Student One',
      avatar_url: 'https://example.com/avatar1.jpg',
    },
  },
  {
    id: 'conv2',
    user_id: 'student2',
    llm_conversation_id: 'llm2',
    workflow_state: 'active',
    created_at: '2025-01-02T00:00:00Z',
    updated_at: '2025-01-02T01:00:00Z',
    has_conversation: true,
    student: {
      id: 'student2',
      name: 'Student Two',
      avatar_url: 'https://example.com/avatar2.jpg',
    },
  },
  {
    id: null,
    user_id: 'student3',
    has_conversation: false,
    student: {
      id: 'student3',
      name: 'Student Three',
      avatar_url: 'https://example.com/avatar3.jpg',
    },
  },
]

const mockConversationDetail = {
  id: 'conv1',
  user_id: 'student1',
  llm_conversation_id: 'llm1',
  workflow_state: 'active',
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T01:00:00Z',
  messages: [
    {
      role: 'User',
      text: 'Hello',
      timestamp: '2025-01-01T00:00:00Z',
    },
    {
      role: 'Assistant',
      text: 'Hi there!',
      timestamp: '2025-01-01T00:01:00Z',
    },
    {
      role: 'User',
      text: 'How are you?',
      timestamp: '2025-01-01T00:02:00Z',
    },
    {
      role: 'Assistant',
      text: 'I am doing well!',
      timestamp: '2025-01-01T00:03:00Z',
    },
  ],
  progress: {
    current: 2,
    total: 4,
    percentage: 50,
    objectives: [],
  },
}

describe('AIConversationsPage', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    server.use(
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations', () => {
        return HttpResponse.json({conversations: mockConversations})
      }),
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations/conv1', () => {
        return HttpResponse.json(mockConversationDetail)
      }),
    )
  })

  afterEach(() => {
    vi.clearAllMocks()
    server.resetHandlers()
  })

  it('renders page title and student dropdown', async () => {
    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('AI Conversations')).toBeInTheDocument()
      expect(screen.getByText('Student')).toBeInTheDocument()
    })
  })

  it('displays all students including those without conversations', async () => {
    const user = userEvent.setup()

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Student')).toBeInTheDocument()
    })

    // Click dropdown to open it
    const dropdown = screen.getByLabelText('Student')
    await user.click(dropdown)

    await waitFor(() => {
      expect(screen.getByText('Student One')).toBeInTheDocument()
      expect(screen.getByText('Student Two')).toBeInTheDocument()
      expect(screen.getByText('Student Three')).toBeInTheDocument()
    })
  })

  it('includes students without conversations in dropdown', async () => {
    const user = userEvent.setup()
    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Student')).toBeInTheDocument()
    })

    // Click dropdown to open it
    const dropdown = screen.getByLabelText('Student')
    await user.click(dropdown)

    await waitFor(() => {
      // All three students should be in the dropdown including the one without a conversation
      expect(screen.getByText('Student One')).toBeInTheDocument()
      expect(screen.getByText('Student Two')).toBeInTheDocument()
      expect(screen.getByText('Student Three')).toBeInTheDocument()
    })
  })

  it('shows placeholder when no student is selected', async () => {
    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Select a student to view their conversation')).toBeInTheDocument()
    })
  })

  it('displays helpful message when student without conversation is selected', async () => {
    const user = userEvent.setup()

    // Set initial hash to student3 (no conversation)
    window.location.hash = 'user_student3'

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(
        screen.getByText('This student has not started a conversation yet'),
      ).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })

  it('loads and displays conversation when student with conversation is selected', async () => {
    // Set initial hash to conv1
    window.location.hash = 'conv1'

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Hi there!')).toBeInTheDocument()
      expect(screen.getByText('How are you?')).toBeInTheDocument()
      expect(screen.getByText('I am doing well!')).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })

  it('displays message counts', async () => {
    // Set initial hash to conv1
    window.location.hash = 'conv1'

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText(/2 Messages by AI/)).toBeInTheDocument()
      // Student count excludes first User message (trigger message)
      expect(screen.getByText(/1 Messages by student/)).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })

  it('displays last updated date', async () => {
    // Set initial hash to conv1
    window.location.hash = 'conv1'

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText(/Last Updated/)).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })

  it('shows conversation tab by default', async () => {
    // Set initial hash to conv1
    window.location.hash = 'conv1'

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Conversation')).toBeInTheDocument()
      expect(screen.getByText('AI analysis')).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })

  it('updates URL hash when student is selected', async () => {
    const user = userEvent.setup()

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Student')).toBeInTheDocument()
    })

    const dropdown = screen.getByLabelText('Student')
    await user.click(dropdown)

    await waitFor(() => {
      expect(screen.getByText('Student One')).toBeInTheDocument()
    })

    const studentOption = screen.getByText('Student One')
    await user.click(studentOption)

    await waitFor(() => {
      expect(window.location.hash).toBe('#conv1')
    })

    // Clean up
    window.location.hash = ''
  })

  it('responds to hash changes for navigation', async () => {
    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Student')).toBeInTheDocument()
    })

    // Simulate browser back/forward navigation
    window.location.hash = 'conv1'
    window.dispatchEvent(new HashChangeEvent('hashchange'))

    await waitFor(() => {
      expect(screen.getByText('Hi there!')).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })

  it('shows loading state while fetching conversations', () => {
    server.use(
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations', async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return HttpResponse.json({conversations: mockConversations})
      }),
    )

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    const dropdown = screen.getByLabelText('Student')
    expect(dropdown).toBeDisabled()
  })

  it('loads and displays conversation when URL hash is set', async () => {
    // Set initial hash to conv1
    window.location.hash = 'conv1'

    render(<AIConversationsPage aiExperience={mockAiExperience} courseId="123" />)

    // Eventually conversation should load and display
    await waitFor(() => {
      expect(screen.getByText('Hi there!')).toBeInTheDocument()
    })

    // Clean up
    window.location.hash = ''
  })
})
