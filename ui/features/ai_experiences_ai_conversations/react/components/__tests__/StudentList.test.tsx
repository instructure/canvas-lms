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
import StudentList from '../StudentList'

describe('StudentList', () => {
  const mockOnSelectStudent = jest.fn()

  beforeEach(() => {
    fetchMock.restore()
    mockOnSelectStudent.mockClear()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('shows loading state initially', () => {
    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations',
      new Promise(() => {}), // Never resolves
      {delay: 100},
    )

    render(
      <StudentList
        courseId="123"
        aiExperienceId="1"
        selectedConversationId={undefined}
        onSelectStudent={mockOnSelectStudent}
      />,
    )

    expect(screen.getByText(/Loading student conversations/i)).toBeInTheDocument()
  })

  it('displays list of students with conversations', async () => {
    const mockConversations = [
      {
        id: 'conv-1',
        user_id: '10',
        llm_conversation_id: 'llm-1',
        workflow_state: 'active',
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-20T00:00:00Z',
        student: {
          id: '10',
          name: 'John Doe',
          avatar_url: 'http://example.com/avatar.jpg',
        },
      },
      {
        id: 'conv-2',
        user_id: '11',
        llm_conversation_id: 'llm-2',
        workflow_state: 'completed',
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-19T00:00:00Z',
        student: {
          id: '11',
          name: 'Jane Smith',
        },
      },
    ]

    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', {
      conversations: mockConversations,
    })

    render(
      <StudentList
        courseId="123"
        aiExperienceId="1"
        selectedConversationId={undefined}
        onSelectStudent={mockOnSelectStudent}
      />,
    )

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
      expect(screen.getByText('Jane Smith')).toBeInTheDocument()
    })
  })

  it('calls onSelectStudent when student is clicked', async () => {
    const mockConversations = [
      {
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
      },
    ]

    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', {
      conversations: mockConversations,
    })

    render(
      <StudentList
        courseId="123"
        aiExperienceId="1"
        selectedConversationId={undefined}
        onSelectStudent={mockOnSelectStudent}
      />,
    )

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
    })

    const studentItem = screen.getByTestId('student-conversation-conv-1')
    await userEvent.click(studentItem)

    expect(mockOnSelectStudent).toHaveBeenCalledWith('conv-1')
  })

  it('renders completed conversations', async () => {
    const mockConversations = [
      {
        id: 'conv-1',
        user_id: '10',
        llm_conversation_id: 'llm-1',
        workflow_state: 'completed',
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-20T00:00:00Z',
        student: {
          id: '10',
          name: 'John Doe',
          avatar_url: 'http://example.com/avatar.jpg',
        },
      },
    ]

    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', {
      conversations: mockConversations,
    })

    render(
      <StudentList
        courseId="123"
        aiExperienceId="1"
        selectedConversationId={undefined}
        onSelectStudent={mockOnSelectStudent}
      />,
    )

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
    })
  })

  it('shows empty state when no conversations exist', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', {
      conversations: [],
    })

    render(
      <StudentList
        courseId="123"
        aiExperienceId="1"
        selectedConversationId={undefined}
        onSelectStudent={mockOnSelectStudent}
      />,
    )

    await waitFor(() => {
      expect(screen.getByText(/No student conversations yet/i)).toBeInTheDocument()
    })
  })

  it('shows error state on API failure', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', 500)

    render(
      <StudentList
        courseId="123"
        aiExperienceId="1"
        selectedConversationId={undefined}
        onSelectStudent={mockOnSelectStudent}
      />,
    )

    await waitFor(() => {
      expect(screen.getByText(/Error loading conversations/i)).toBeInTheDocument()
    })
  })
})
