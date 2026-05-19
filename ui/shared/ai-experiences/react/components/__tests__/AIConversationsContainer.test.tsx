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

import '@instructure/canvas-theme'
import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import AIConversationsContainer from '../AIConversationsContainer'
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
    student: {id: 'student1', name: 'Student One', avatar_url: 'https://example.com/avatar1.jpg'},
  },
  {
    id: 'conv2',
    user_id: 'student2',
    llm_conversation_id: 'llm2',
    workflow_state: 'active',
    created_at: '2025-01-02T00:00:00Z',
    updated_at: '2025-01-02T01:00:00Z',
    has_conversation: true,
    student: {id: 'student2', name: 'Student Two', avatar_url: 'https://example.com/avatar2.jpg'},
  },
  {
    id: null,
    user_id: 'student3',
    has_conversation: false,
    student: {id: 'student3', name: 'Student Three', avatar_url: 'https://example.com/avatar3.jpg'},
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
    {role: 'User', text: 'Hello', timestamp: '2025-01-01T00:00:00Z'},
    {role: 'Assistant', text: 'Hi there!', timestamp: '2025-01-01T00:01:00Z'},
    {role: 'User', text: 'How are you?', timestamp: '2025-01-01T00:02:00Z'},
    {role: 'Assistant', text: 'I am doing well!', timestamp: '2025-01-01T00:03:00Z'},
  ],
  progress: {current: 2, total: 4, percentage: 50, objectives: []},
}

describe('AIConversationsContainer', () => {
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

  it('renders filter by student dropdown', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByLabelText('Filter by student')).toBeInTheDocument()
    })
  })

  it('auto-selects first student with a conversation on load', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByText('Student One')).toBeInTheDocument()
    })
  })

  it('displays all students in dropdown including those without conversations', async () => {
    const user = userEvent.setup()
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByLabelText('Filter by student')).toBeInTheDocument()
    })

    await user.click(screen.getByLabelText('Filter by student'))

    await waitFor(() => {
      expect(screen.getByText('✓ Student One')).toBeInTheDocument()
      expect(screen.getByText('✓ Student Two')).toBeInTheDocument()
      expect(screen.getByText('Student Three (No conversation)')).toBeInTheDocument()
    })
  })

  it('disables dropdown options for students without conversations', async () => {
    const user = userEvent.setup()
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByLabelText('Filter by student')).toBeInTheDocument()
    })

    await user.click(screen.getByLabelText('Filter by student'))

    await waitFor(() => {
      expect(screen.getByText('Student Three (No conversation)')).toBeInTheDocument()
    })

    const studentThreeOption = screen
      .getByText('Student Three (No conversation)')
      .closest('span[role="option"]')
    expect(studentThreeOption).toHaveAttribute('aria-disabled', 'true')

    const studentOneOption = screen.getByText('✓ Student One').closest('span[role="option"]')
    expect(studentOneOption).not.toHaveAttribute('aria-disabled', 'true')
  })

  it('shows student name heading when a student with a conversation is selected', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByTestId('ai-conversations-student-heading')).toBeInTheDocument()
    })
  })

  it('loads conversation messages into Knowledge Chat card', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByText('Hi there!')).toBeInTheDocument()
      expect(screen.getByText('I am doing well!')).toBeInTheDocument()
    })
  })

  it('shows Knowledge Chat card header', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByText('Knowledge Chat')).toBeInTheDocument()
    })
  })

  it('renders Expand button inside the Knowledge Chat card', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByTestId('ai-conversations-expand-button')).toBeInTheDocument()
    })
  })

  it('shows in-progress pill when conversation is active', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByText('In progress')).toBeInTheDocument()
    })
  })

  it('shows IgniteAI and Student message count pills', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByText('IgniteAI messages: 2')).toBeInTheDocument()
      expect(screen.getByText('Student messages: 1')).toBeInTheDocument()
    })
  })

  it('shows helpful message when navigating to a student without a conversation', async () => {
    const user = userEvent.setup()

    server.use(
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations/conv2', () => {
        return HttpResponse.json({
          ...mockConversationDetail,
          id: 'conv2',
          user_id: 'student2',
          messages: [],
          progress: null,
        })
      }),
    )

    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

    // Auto-selects Student One; click Next twice to reach Student Three (no conversation)
    await waitFor(() => {
      expect(screen.getByText('Student One')).toBeInTheDocument()
    })

    await user.click(screen.getByTestId('ai-conversations-next-button'))
    await waitFor(() => {
      expect(screen.getByTestId('ai-conversations-student-heading')).toBeInTheDocument()
    })

    await user.click(screen.getByTestId('ai-conversations-next-button'))
    await waitFor(() => {
      expect(
        screen.getByText('This student has not started a conversation yet'),
      ).toBeInTheDocument()
    })
  })

  it('shows empty state message when no student is selected', async () => {
    server.use(
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations', () => {
        return HttpResponse.json({conversations: []})
      }),
    )

    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Select a student to view their conversation')).toBeInTheDocument()
    })
  })

  it('disables dropdown while conversations are loading', () => {
    server.use(
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations', async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return HttpResponse.json({conversations: mockConversations})
      }),
    )

    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

    expect(screen.getByLabelText('Filter by student')).toBeDisabled()
  })

  it('renders Previous and Next navigation buttons', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByTestId('ai-conversations-previous-button')).toBeInTheDocument()
      expect(screen.getByTestId('ai-conversations-next-button')).toBeInTheDocument()
    })
  })

  it('Previous button is disabled when first student is selected', async () => {
    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
    await waitFor(() => {
      expect(screen.getByText('Student One')).toBeInTheDocument()
    })
    const prevButton = screen.getByTestId('ai-conversations-previous-button')
    expect(prevButton).toHaveAttribute('disabled')
  })

  it('Next button navigates to next student', async () => {
    const user = userEvent.setup()

    server.use(
      http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations/conv2', () => {
        return HttpResponse.json({
          ...mockConversationDetail,
          id: 'conv2',
          user_id: 'student2',
          messages: [],
          progress: null,
        })
      }),
    )

    render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

    await waitFor(() => {
      expect(screen.getByText('Student One')).toBeInTheDocument()
    })

    await user.click(screen.getByTestId('ai-conversations-next-button'))

    await waitFor(() => {
      expect(screen.getByTestId('ai-conversations-student-heading')).toBeInTheDocument()
    })
  })

  describe('pre-selection logic', () => {
    it('pre-selects first student with conversation when list loads', async () => {
      render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)
      await waitFor(() => {
        expect(screen.getByTestId('ai-conversations-student-heading')).toBeInTheDocument()
      })
    })

    it('pre-selects first student when none have conversations', async () => {
      const conversationsWithoutAny = [
        {
          id: null,
          user_id: 'student1',
          has_conversation: false,
          student: {id: 'student1', name: 'Student One'},
        },
        {
          id: null,
          user_id: 'student2',
          has_conversation: false,
          student: {id: 'student2', name: 'Student Two'},
        },
      ]

      server.use(
        http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations', () => {
          return HttpResponse.json({conversations: conversationsWithoutAny})
        }),
      )

      render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

      await waitFor(() => {
        expect(
          screen.getByText('This student has not started a conversation yet'),
        ).toBeInTheDocument()
      })
    })

    it('pre-selects student with conversation even if not first in list', async () => {
      const conversationsReordered = [
        {
          id: null,
          user_id: 'student3',
          has_conversation: false,
          student: {id: 'student3', name: 'Student Three'},
        },
        {
          id: 'conv2',
          user_id: 'student2',
          llm_conversation_id: 'llm2',
          workflow_state: 'active',
          created_at: '2025-01-02T00:00:00Z',
          updated_at: '2025-01-02T01:00:00Z',
          has_conversation: true,
          student: {id: 'student2', name: 'Student Two'},
        },
      ]

      server.use(
        http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations', () => {
          return HttpResponse.json({conversations: conversationsReordered})
        }),
        http.get('/api/v1/courses/123/ai_experiences/1/ai_conversations/conv2', () => {
          return HttpResponse.json({
            ...mockConversationDetail,
            id: 'conv2',
            user_id: 'student2',
            messages: [],
            progress: null,
          })
        }),
      )

      render(<AIConversationsContainer aiExperience={mockAiExperience} courseId="123" />)

      await waitFor(() => {
        expect(screen.getByTestId('ai-conversations-student-heading')).toBeInTheDocument()
      })
    })
  })
})
