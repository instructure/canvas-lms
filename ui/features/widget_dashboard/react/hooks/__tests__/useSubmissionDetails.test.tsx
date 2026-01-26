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
import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useSubmissionDetails} from '../useSubmissionDetails'

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  window.ENV = {current_user_id: '1'} as any
})

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

const mockSubmissionDetailsResponse = {
  data: {
    legacyNode: {
      _id: 'sub1',
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 'rubric1',
            score: 85,
            assessmentRatings: [
              {
                _id: 'rating1',
                criterion: {
                  _id: 'criterion1',
                  description: 'Content Quality',
                  longDescription: 'How well does the content address the topic?',
                  points: 50,
                },
                description: 'Good work',
                points: 45,
                comments: 'Nice job on the analysis',
                commentsHtml: '<p>Nice job on the analysis</p>',
              },
              {
                _id: 'rating2',
                criterion: {
                  _id: 'criterion2',
                  description: 'Grammar',
                  longDescription: null,
                  points: 50,
                },
                description: 'Excellent',
                points: 40,
                comments: null,
                commentsHtml: null,
              },
            ],
          },
        ],
      },
      recentCommentsConnection: {
        nodes: [
          {
            _id: 'comment1',
            comment: 'Great work on this assignment!',
            htmlComment: '<p>Great work on this assignment!</p>',
            author: {
              _id: 'teacher1',
              name: 'Mr. Smith',
            },
            createdAt: '2025-11-30T14:30:00Z',
          },
        ],
      },
      allCommentsConnection: {
        pageInfo: {
          totalCount: 3,
        },
      },
    },
  },
}

describe('useSubmissionDetails', () => {
  it('fetches submission details successfully', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json(mockSubmissionDetailsResponse)
      }),
    )

    const {result} = renderHook(() => useSubmissionDetails('sub1'), {
      wrapper: createWrapper(),
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.data).toEqual({
      rubricAssessments: [
        {
          _id: 'rubric1',
          score: 85,
          assessmentRatings: [
            {
              _id: 'rating1',
              criterion: {
                _id: 'criterion1',
                description: 'Content Quality',
                longDescription: 'How well does the content address the topic?',
                points: 50,
              },
              description: 'Good work',
              points: 45,
              comments: 'Nice job on the analysis',
              commentsHtml: '<p>Nice job on the analysis</p>',
            },
            {
              _id: 'rating2',
              criterion: {
                _id: 'criterion2',
                description: 'Grammar',
                longDescription: null,
                points: 50,
              },
              description: 'Excellent',
              points: 40,
              comments: null,
              commentsHtml: null,
            },
          ],
        },
      ],
      comments: [
        {
          _id: 'comment1',
          comment: 'Great work on this assignment!',
          htmlComment: '<p>Great work on this assignment!</p>',
          author: {
            _id: 'teacher1',
            name: 'Mr. Smith',
          },
          createdAt: '2025-11-30T14:30:00Z',
        },
      ],
      totalCommentsCount: 3,
    })
  })

  it('handles empty rubric and comments', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: 'sub1',
              rubricAssessmentsConnection: {
                nodes: [],
              },
              recentCommentsConnection: {
                nodes: [],
              },
              allCommentsConnection: {
                pageInfo: {
                  totalCount: 0,
                },
              },
            },
          },
        })
      }),
    )

    const {result} = renderHook(() => useSubmissionDetails('sub1'), {
      wrapper: createWrapper(),
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.data).toEqual({
      rubricAssessments: [],
      comments: [],
      totalCommentsCount: 0,
    })
  })

  it('handles null submission ID', async () => {
    const {result} = renderHook(() => useSubmissionDetails(null), {
      wrapper: createWrapper(),
    })

    expect(result.current.data).toBeUndefined()
    expect(result.current.isLoading).toBe(false)
  })

  it('handles GraphQL errors', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json({
          errors: [{message: 'GraphQL error'}],
        })
      }),
    )

    const {result} = renderHook(() => useSubmissionDetails('sub1'), {
      wrapper: createWrapper(),
    })

    await waitFor(() => expect(result.current.error).toBeTruthy())
    expect(result.current.error).toBeTruthy()
  })

  it('handles null legacyNode response', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json({
          data: {
            legacyNode: null,
          },
        })
      }),
    )

    const {result} = renderHook(() => useSubmissionDetails('sub1'), {
      wrapper: createWrapper(),
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.data).toEqual({
      rubricAssessments: [],
      comments: [],
      totalCommentsCount: 0,
    })
  })
})
