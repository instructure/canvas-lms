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

import {waitFor} from '@testing-library/react'
import {renderHook, act} from '@testing-library/react-hooks'
import fetchMock from 'fetch-mock'
import {useConversationEvaluation} from '../useConversationEvaluation'

describe('useConversationEvaluation', () => {
  beforeEach(() => {
    fetchMock.restore()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  const mockEvaluation = {
    overall_assessment: 'Student demonstrated strong analytical skills.',
    key_moments: [
      {
        learning_objective: 'Critical thinking',
        evidence: 'Student analyzed the problem systematically',
        message_number: 3,
      },
    ],
    learning_objectives_evaluation: [
      {
        objective: 'Critical thinking',
        met: true,
        score: 85,
        explanation: 'Student showed excellent analytical skills',
      },
      {
        objective: 'Historical context',
        met: false,
        score: 45,
        explanation: 'Student needs more practice',
      },
    ],
    strengths: ['Clear communication', 'Systematic approach'],
    areas_for_improvement: ['Historical context analysis'],
    overall_score: 85,
  }

  it('does not fetch evaluation on mount', () => {
    const {result} = renderHook(() => useConversationEvaluation('123', '1', 'conv-1'))

    expect(result.current.evaluation).toBeNull()
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
    expect(fetchMock.calls()).toHaveLength(0)
  })

  it('fetches evaluation when fetchEvaluation is called', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/conversations/conv-1/evaluation', {
      evaluation: mockEvaluation,
    })

    const {result} = renderHook(() => useConversationEvaluation('123', '1', 'conv-1'))

    expect(result.current.isLoading).toBe(false)

    act(() => {
      result.current.fetchEvaluation()
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(true)
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.evaluation).toEqual(mockEvaluation)
    expect(result.current.error).toBeNull()
  })

  it('does not fetch when conversationId is undefined', async () => {
    const {result} = renderHook(() => useConversationEvaluation('123', '1', undefined))

    await act(async () => {
      result.current.fetchEvaluation()
    })

    expect(fetchMock.calls()).toHaveLength(0)
    expect(result.current.evaluation).toBeNull()
  })

  it('handles API errors', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/conversations/conv-1/evaluation', 500)

    const {result} = renderHook(() => useConversationEvaluation('123', '1', 'conv-1'))

    await act(async () => {
      result.current.fetchEvaluation()
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.evaluation).toBeNull()
    expect(result.current.error).toBeTruthy()
  })

  it('resets evaluation when conversationId changes', () => {
    const {result, rerender} = renderHook(
      ({conversationId}: {conversationId?: string}) =>
        useConversationEvaluation('123', '1', conversationId),
      {initialProps: {conversationId: 'conv-1'}},
    )

    // Set some evaluation data
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/conversations/conv-1/evaluation', {
      evaluation: mockEvaluation,
    })

    act(() => {
      result.current.fetchEvaluation()
    })

    // Change conversation ID
    rerender({conversationId: 'conv-2'})

    // Evaluation should be reset
    expect(result.current.evaluation).toBeNull()
    expect(result.current.error).toBeNull()
  })

  it('can fetch evaluation multiple times', async () => {
    const updatedEvaluation = {...mockEvaluation, overall_score: 90}

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/conversations/conv-1/evaluation',
      {evaluation: mockEvaluation},
      {repeat: 1},
    )

    fetchMock.get(
      'path:/api/v1/courses/123/ai_experiences/1/conversations/conv-1/evaluation',
      {evaluation: updatedEvaluation},
      {repeat: 1, overwriteRoutes: false},
    )

    const {result} = renderHook(() => useConversationEvaluation('123', '1', 'conv-1'))

    // First fetch
    await act(async () => {
      result.current.fetchEvaluation()
    })

    await waitFor(() => {
      expect(result.current.evaluation?.overall_score).toBe(85)
    })

    // Second fetch
    await act(async () => {
      result.current.fetchEvaluation()
    })

    await waitFor(() => {
      expect(result.current.evaluation?.overall_score).toBe(90)
    })
  })

  it('sets error state correctly', async () => {
    fetchMock.get('path:/api/v1/courses/123/ai_experiences/1/conversations/conv-1/evaluation', {
      status: 503,
      body: {error: 'Service temporarily unavailable'},
    })

    const {result} = renderHook(() => useConversationEvaluation('123', '1', 'conv-1'))

    await act(async () => {
      result.current.fetchEvaluation()
    })

    await waitFor(() => {
      expect(result.current.error).toBeTruthy()
    })

    expect(result.current.evaluation).toBeNull()
  })
})
