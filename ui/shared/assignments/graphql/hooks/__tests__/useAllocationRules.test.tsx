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

import {renderHook} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {QueryClient} from '@tanstack/react-query'
import React from 'react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {useAllocationRules} from '../useAllocationRules'
import {AllocationRuleType} from '../../teacher/AssignmentTeacherTypes'

import {executeQuery} from '@canvas/graphql'

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

const mockExecuteQuery = vi.mocked(executeQuery)

const mockAllocationRules: AllocationRuleType[] = [
  {
    _id: '1',
    mustReview: true,
    reviewPermitted: true,
    appliesToAssessor: true,
    assessor: {
      _id: 'assessor-1',
      name: 'Mudkip',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
    assessee: {
      _id: 'assessee-1',
      name: 'Torchic',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
  },
  {
    _id: '2',
    mustReview: false,
    reviewPermitted: true,
    appliesToAssessor: false,
    assessor: {
      _id: 'assessor-2',
      name: 'Latias',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
    assessee: {
      _id: 'assessee-2',
      name: 'Latios',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
  },
]

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
  )
}

describe('useAllocationRules', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockExecuteQuery.mockClear()
  })

  it('initializes with loading state and returns rules successfully', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        allocationRules: {
          rulesConnection: {
            nodes: mockAllocationRules,
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
          count: 2,
        },
      },
    })

    const {result} = renderHook(() => useAllocationRules('assignment-123', 1, 10), {
      wrapper: createWrapper(),
    })

    expect(result.current.loading).toBe(true)
    expect(result.current.rules).toEqual([])
    expect(result.current.totalCount).toBe(null)
    expect(result.current.error).toBe(null)

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.rules).toEqual(mockAllocationRules)
    expect(result.current.totalCount).toBe(2)
    expect(result.current.error).toBe(null)
  })

  it('handles query error', async () => {
    mockExecuteQuery.mockRejectedValueOnce(new Error('Assignment not found'))

    const {result} = renderHook(() => useAllocationRules('assignment-error', 1, 10), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.rules).toEqual([])
    expect(result.current.totalCount).toBe(null)
    expect(result.current.error).toBeTruthy()
    expect(result.current.error?.message).toBe('Assignment not found')
  })

  it('returns empty array when no rules found', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        allocationRules: {
          rulesConnection: {
            nodes: [],
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
          count: 0,
        },
      },
    })

    const {result} = renderHook(() => useAllocationRules('assignment-empty', 1, 10), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.rules).toEqual([])
    expect(result.current.totalCount).toBe(null)
    expect(result.current.error).toBe(null)
  })

  it('is disabled when assignmentId is empty', () => {
    const {result} = renderHook(() => useAllocationRules('', 1, 10), {
      wrapper: createWrapper(),
    })

    expect(result.current.loading).toBe(false)
    expect(result.current.rules).toEqual([])
    expect(result.current.totalCount).toBe(null)
    expect(result.current.error).toBe(null)
    expect(mockExecuteQuery).not.toHaveBeenCalled()
  })

  it('correctly handles pagination across multiple GraphQL pages', async () => {
    const createMockRules = (start: number, count: number) =>
      Array.from({length: count}, (_, i) => ({
        _id: `rule-${start + i}`,
        mustReview: i % 2 === 0,
        reviewPermitted: true,
        appliesToAssessor: true,
        assessor: {
          _id: `assessor-${start + i}`,
          name: `Assessor ${start + i}`,
          peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
        },
        assessee: {
          _id: `assessee-${start + i}`,
          name: `Assessee ${start + i}`,
          peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
        },
      }))

    mockExecuteQuery
      .mockResolvedValueOnce({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: createMockRules(0, 20),
              pageInfo: {
                hasNextPage: true,
                endCursor: 'cursor-20',
              },
            },
            count: 45,
          },
        },
      })
      .mockResolvedValueOnce({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: createMockRules(20, 20),
              pageInfo: {
                hasNextPage: true,
                endCursor: 'cursor-40',
              },
            },
            count: 45,
          },
        },
      })
      .mockResolvedValueOnce({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: createMockRules(40, 5),
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
              },
            },
            count: 45,
          },
        },
      })

    const {result} = renderHook(() => useAllocationRules('assignment-123', 11, 4), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    expect(result.current.rules).toHaveLength(4)
    expect(result.current.rules[0]._id).toBe('rule-40')
    expect(result.current.rules[3]._id).toBe('rule-43')
    expect(result.current.totalCount).toBe(45)
    expect(mockExecuteQuery).toHaveBeenCalledTimes(3)
  })

  it('refetch clears cache and fetches fresh data', async () => {
    mockExecuteQuery.mockResolvedValue({
      assignment: {
        allocationRules: {
          rulesConnection: {
            nodes: mockAllocationRules,
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
          count: 2,
        },
      },
    })

    const {result} = renderHook(() => useAllocationRules('assignment-123', 1, 10), {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })

    mockExecuteQuery.mockClear()
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        allocationRules: {
          rulesConnection: {
            nodes: [
              ...mockAllocationRules,
              {
                _id: '3',
                mustReview: true,
                reviewPermitted: false,
                appliesToAssessor: true,
                assessor: {
                  _id: 'assessor-3',
                  name: 'New Assessor',
                  peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
                },
                assessee: {
                  _id: 'assessee-3',
                  name: 'New Assessee',
                  peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
                },
              },
            ],
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
          count: 3,
        },
      },
    })

    const refetchResult = await result.current.refetch(1)

    expect(refetchResult.rules).toHaveLength(3)
    expect(refetchResult.totalCount).toBe(3)
    expect(mockExecuteQuery).toHaveBeenCalledTimes(1)
  })

  describe('search term handling', () => {
    it('passes undefined for empty search term', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules,
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
              },
            },
            count: 2,
          },
        },
      })

      const {result} = renderHook(() => useAllocationRules('assignment-123', 1, 10, ''), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.loading).toBe(false)
      })

      expect(result.current.rules).toEqual(mockAllocationRules)
      expect(result.current.totalCount).toBe(2)
      expect(result.current.error).toBe(null)

      expect(mockExecuteQuery).toHaveBeenCalledWith(
        expect.any(Object),
        expect.objectContaining({
          assignmentId: 'assignment-123',
          after: null,
          searchTerm: undefined,
        }),
      )
    })

    it('passes search term when provided', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [mockAllocationRules[0]],
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
              },
            },
            count: 1,
          },
        },
      })

      const {result} = renderHook(() => useAllocationRules('assignment-123', 1, 10, 'Mudkip'), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.loading).toBe(false)
      })

      expect(result.current.rules).toEqual([mockAllocationRules[0]])
      expect(result.current.totalCount).toBe(1)
      expect(result.current.error).toBe(null)

      expect(mockExecuteQuery).toHaveBeenCalledWith(expect.any(Object), {
        assignmentId: 'assignment-123',
        after: null,
        searchTerm: 'Mudkip',
      })
    })

    it('handles whitespace-only search term as undefined', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules,
              pageInfo: {
                hasNextPage: false,
                endCursor: null,
              },
            },
            count: 2,
          },
        },
      })

      const {result} = renderHook(() => useAllocationRules('assignment-123', 1, 10, '   '), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.loading).toBe(false)
      })

      expect(result.current.rules).toEqual(mockAllocationRules)
      expect(result.current.totalCount).toBe(2)
      expect(result.current.error).toBe(null)

      expect(mockExecuteQuery).toHaveBeenCalledWith(
        expect.any(Object),
        expect.objectContaining({
          assignmentId: 'assignment-123',
          after: null,
          searchTerm: undefined,
        }),
      )
    })
  })
})
