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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import fetchMock from 'fetch-mock'
import {useStudentConversations, useConversationDetail} from '../useAIConversations'

describe('useStudentConversations', () => {
  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('fetches student conversations on mount', async () => {
    const mockConversations = [
      {
        id: 'conv-1',
        user_id: '10',
        student: {id: '10', name: 'John Doe'},
      },
    ]

    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', {
      conversations: mockConversations,
    })

    const {result} = renderHook(() => useStudentConversations('123', '1'))

    expect(result.current.isLoading).toBe(true)
    expect(result.current.conversations).toEqual([])

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.conversations).toEqual(mockConversations)
    expect(result.current.error).toBeNull()
  })

  it('handles API errors', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', 500)

    const {result} = renderHook(() => useStudentConversations('123', '1'))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.conversations).toEqual([])
    expect(result.current.error).toBeTruthy()
  })

  it('handles empty conversations list', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations', {
      conversations: [],
    })

    const {result} = renderHook(() => useStudentConversations('123', '1'))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.conversations).toEqual([])
    expect(result.current.error).toBeNull()
  })
})

describe('useConversationDetail', () => {
  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('does not fetch when conversationId is undefined', () => {
    const {result} = renderHook(() => useConversationDetail('123', '1', undefined))

    expect(result.current.conversation).toBeNull()
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
    expect(fetchMock.calls()).toHaveLength(0)
  })

  it('fetches conversation detail when conversationId is provided', async () => {
    const mockConversation = {
      id: 'conv-1',
      messages: [{role: 'assistant', content: 'Hello!'}],
      progress: {status: 'in_progress'},
    }

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      mockConversation,
    )

    const {result} = renderHook(() => useConversationDetail('123', '1', 'conv-1'))

    expect(result.current.isLoading).toBe(true)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.conversation).toEqual(mockConversation)
    expect(result.current.error).toBeNull()
  })

  it('refetches when conversationId changes', async () => {
    const mockConversation1 = {
      id: 'conv-1',
      messages: [{role: 'assistant', content: 'Hello from conv-1!'}],
    }

    const mockConversation2 = {
      id: 'conv-2',
      messages: [{role: 'assistant', content: 'Hello from conv-2!'}],
    }

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      mockConversation1,
    )
    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-2',
      mockConversation2,
    )

    const {result, rerender} = renderHook(
      ({conversationId}) => useConversationDetail('123', '1', conversationId),
      {initialProps: {conversationId: 'conv-1'}},
    )

    await waitFor(() => {
      expect(result.current.conversation?.id).toBe('conv-1')
    })

    rerender({conversationId: 'conv-2'})

    await waitFor(() => {
      expect(result.current.conversation?.id).toBe('conv-2')
    })
  })

  it('clears conversation when conversationId becomes undefined', async () => {
    const mockConversation = {
      id: 'conv-1',
      messages: [],
    }

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1',
      mockConversation,
    )

    const {result, rerender} = renderHook(
      ({conversationId}: {conversationId?: string}) =>
        useConversationDetail('123', '1', conversationId),
      {initialProps: {conversationId: 'conv-1' as string | undefined}},
    )

    await waitFor(() => {
      expect(result.current.conversation).toBeTruthy()
    })

    rerender({conversationId: undefined})

    expect(result.current.conversation).toBeNull()
  })

  it('handles API errors', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/ai_conversations/conv-1', 500)

    const {result} = renderHook(() => useConversationDetail('123', '1', 'conv-1'))

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.conversation).toBeNull()
    expect(result.current.error).toBeTruthy()
  })
})
