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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useSavePeerReviewRubricAssessment} from '../useSavePeerReviewRubricAssessment'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'

vi.mock('@canvas/do-fetch-api-effect')

describe('useSavePeerReviewRubricAssessment', () => {
  let queryClient: QueryClient

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
        mutations: {retry: false},
      },
    })
    vi.clearAllMocks()
  })

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  const createAssessments = (): RubricAssessmentData[] => [
    {
      id: 'rating-1',
      points: 4,
      criterionId: '1',
      comments: 'Great work!',
      commentsEnabled: true,
      description: 'Excellent',
    },
    {
      id: 'rating-2',
      points: 3,
      criterionId: '2',
      comments: 'Good effort',
      commentsEnabled: true,
      description: 'Good',
    },
  ]

  it('successfully saves rubric assessment with user ID', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    const assessments = createAssessments()
    result.current.mutate({
      assessments,
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(doFetchApi).toHaveBeenCalledWith({
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      path: '/courses/123/rubric_associations/456/assessments',
      body: expect.stringContaining('rubric_assessment'),
    })
  })

  it('successfully saves rubric assessment with anonymous ID', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    const assessments = createAssessments()
    result.current.mutate({
      assessments,
      courseId: '123',
      rubricAssociationId: '456',
      anonymousId: 'abc123',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(doFetchApi).toHaveBeenCalledWith({
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      path: '/courses/123/rubric_associations/456/assessments',
      body: expect.stringContaining('rubric_assessment%5Banonymous_id%5D=abc123'),
    })
  })

  it('includes assessment_type=peer_review in request', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    result.current.mutate({
      assessments: createAssessments(),
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const callArgs = vi.mocked(doFetchApi).mock.calls[0][0]
    expect(callArgs.body).toContain('rubric_assessment%5Bassessment_type%5D=peer_review')
  })

  it('includes criterion assessments in request', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    result.current.mutate({
      assessments: createAssessments(),
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const callArgs = vi.mocked(doFetchApi).mock.calls[0][0]
    expect(callArgs.body).toContain('criterion_1')
    expect(callArgs.body).toContain('criterion_2')
    expect(callArgs.body).toContain('%5Bpoints%5D=4')
    expect(callArgs.body).toContain('%5Bpoints%5D=3')
    expect(callArgs.body).toContain('%5Brating_id%5D=rating-1')
    expect(callArgs.body).toContain('%5Brating_id%5D=rating-2')
  })

  it('includes comments in request', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    result.current.mutate({
      assessments: createAssessments(),
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const callArgs = vi.mocked(doFetchApi).mock.calls[0][0]
    expect(callArgs.body).toContain('Great%20work')
    expect(callArgs.body).toContain('Good%20effort')
  })

  it('handles empty comments', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    const assessments: RubricAssessmentData[] = [
      {
        id: 'rating-1',
        points: 4,
        criterionId: '1',
        comments: '',
        commentsEnabled: true,
        description: 'Excellent',
      },
    ]

    result.current.mutate({
      assessments,
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(doFetchApi).toHaveBeenCalled()
  })

  it('handles API errors', async () => {
    const mockError = new Error('Network error')
    vi.mocked(doFetchApi).mockRejectedValue(mockError)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    result.current.mutate({
      assessments: createAssessments(),
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isError).toBe(true))
    expect(result.current.error).toEqual(mockError)
  })

  it('sets isPending during mutation', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockImplementation(
      () =>
        new Promise(resolve => {
          setTimeout(() => resolve(mockResponse), 100)
        }),
    )

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    result.current.mutate({
      assessments: createAssessments(),
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
    })

    await waitFor(() => expect(result.current.isPending).toBe(true))

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.isPending).toBe(false)
  })

  it('prefers anonymous ID over user ID when both provided', async () => {
    const mockResponse = {
      json: {success: true},
      text: '',
      response: new Response(),
    }
    vi.mocked(doFetchApi).mockResolvedValue(mockResponse)

    const {result} = renderHook(() => useSavePeerReviewRubricAssessment(), {wrapper})

    result.current.mutate({
      assessments: createAssessments(),
      courseId: '123',
      rubricAssociationId: '456',
      revieweeUserId: '789',
      anonymousId: 'abc123',
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    const callArgs = vi.mocked(doFetchApi).mock.calls[0][0]
    expect(callArgs.body).toContain('rubric_assessment%5Banonymous_id%5D=abc123')
    expect(callArgs.body).not.toContain('user_id')
  })
})
