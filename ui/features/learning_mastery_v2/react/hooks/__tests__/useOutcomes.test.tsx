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
import {renderHook, act} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useOutcomes} from '../useOutcomes'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {executeQuery} from '@canvas/graphql'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/graphql')

const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

const mockRootOutcomeGroup = {
  id: 1,
  title: 'Root Group',
  vendor_guid: null,
  url: 'http://example.com/root',
  subgroups_url: 'http://example.com/subgroups',
  outcomes_url: 'http://example.com/outcomes',
  can_edit: true,
  import_url: 'http://example.com/import',
  context_id: 123,
  context_type: 'Course',
}

const mockOutcomesData = {
  group: {
    _id: '1',
    description: 'Group description',
    title: 'Group Title',
    outcomesCount: 2,
    notImportedOutcomesCount: 0,
    outcomes: {
      pageInfo: {
        hasNextPage: false,
        endCursor: null,
      },
      edges: [
        {
          canUnlink: true,
          _id: '1',
          node: {
            _id: '1',
            description: 'Outcome 1 description',
            title: 'Outcome 1',
            displayName: 'Outcome 1',
            calculationMethod: 'decaying_average',
            calculationInt: 65,
            masteryPoints: 3,
            ratings: [{description: 'Exceeds', points: 4}],
            canEdit: true,
            canArchive: true,
            contextType: 'Course',
            contextId: '123',
            friendlyDescription: null,
          },
          group: {
            _id: '1',
            title: 'Group 1',
          },
        },
        {
          canUnlink: true,
          _id: '2',
          node: {
            _id: '2',
            description: 'Outcome 2 description',
            title: 'Outcome 2',
            displayName: 'Outcome 2',
            calculationMethod: 'decaying_average',
            calculationInt: 65,
            masteryPoints: 3,
            ratings: [{description: 'Exceeds', points: 4}],
            canEdit: true,
            canArchive: true,
            contextType: 'Course',
            contextId: '123',
            friendlyDescription: null,
          },
          group: {
            _id: '1',
            title: 'Group 1',
          },
        },
      ],
    },
  },
}

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  }
}

describe('useOutcomes', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('with provided groupId', () => {
    it('fetches outcomes with provided groupId', async () => {
      mockExecuteQuery.mockResolvedValue(mockOutcomesData)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
          }),
        {wrapper: createWrapper()},
      )

      expect(result.current.isLoading).toBe(true)

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.outcomes).toEqual(mockOutcomesData.group.outcomes.edges)
      expect(result.current.outcomesCount).toBe(2)
      expect(result.current.error).toBe(null)
      expect(result.current.hasNextPage).toBe(false)
      expect(result.current.endCursor).toBe(null)
    })

    it('passes searchTerm to executeQuery when provided', async () => {
      mockExecuteQuery.mockResolvedValue(mockOutcomesData)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
            searchTerm: 'test search',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          searchQuery: 'test search',
        }),
      )
    })

    it('trims whitespace from search term', async () => {
      mockExecuteQuery.mockResolvedValue(mockOutcomesData)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
            searchTerm: '  test search  ',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          searchQuery: 'test search',
        }),
      )
    })

    it('does not pass searchQuery when search term is empty', async () => {
      mockExecuteQuery.mockResolvedValue(mockOutcomesData)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
            searchTerm: '   ',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      const calls = mockExecuteQuery.mock.calls
      const lastCall = calls[calls.length - 1]
      expect(lastCall[1]).not.toHaveProperty('searchQuery')
    })

    it('handles error from executeQuery', async () => {
      const error = new Error('Failed to fetch outcomes')
      mockExecuteQuery.mockRejectedValue(error)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.error).toEqual(error)
      })

      expect(result.current.outcomes).toEqual([])
      expect(result.current.outcomesCount).toBe(0)
    })

    it('returns pagination info when hasNextPage is true', async () => {
      const dataWithPagination = {
        ...mockOutcomesData,
        group: {
          ...mockOutcomesData.group,
          outcomes: {
            ...mockOutcomesData.group.outcomes,
            pageInfo: {
              hasNextPage: true,
              endCursor: 'cursor123',
            },
          },
        },
      }
      mockExecuteQuery.mockResolvedValue(dataWithPagination)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.hasNextPage).toBe(true)
      expect(result.current.endCursor).toBe('cursor123')
    })
  })

  describe('without provided groupId', () => {
    it('fetches root outcome group first, then fetches outcomes', async () => {
      mockDoFetchApi.mockResolvedValue({json: mockRootOutcomeGroup} as any)
      mockExecuteQuery.mockResolvedValue(mockOutcomesData)

      const {result, rerender} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
          }),
        {wrapper: createWrapper()},
      )

      expect(result.current.isLoading).toBe(true)

      // Wait for the root group fetch to be called first
      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: '/api/v1/courses/123/root_outcome_group',
          method: 'GET',
        })
      })

      // Force a rerender to allow the second query to pick up the new enabled state
      await act(async () => {
        rerender()
      })

      // Wait for the outcomes query to be called with the group ID from the first query
      await waitFor(() => {
        expect(mockExecuteQuery).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({
            id: '1',
            outcomesContextId: '123',
            outcomesContextType: 'Course',
          }),
        )
      })

      // Wait for loading to complete
      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.outcomes).toEqual(mockOutcomesData.group.outcomes.edges)
      expect(result.current.outcomesCount).toBe(2)
    })

    it('handles error from root outcome group fetch', async () => {
      const error = new Error('Failed to fetch root group')
      mockDoFetchApi.mockRejectedValue(error)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.error).toEqual(error)
      })

      expect(result.current.outcomes).toEqual([])
    })
  })

  describe('enabled parameter', () => {
    it('does not fetch when enabled is false', async () => {
      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
            enabled: false,
          }),
        {wrapper: createWrapper()},
      )

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(mockExecuteQuery).not.toHaveBeenCalled()
      expect(result.current.isLoading).toBe(false)
    })

    it('fetches when enabled is true', async () => {
      mockExecuteQuery.mockResolvedValue(mockOutcomesData)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
            enabled: true,
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalled()
    })
  })

  describe('return values when data is missing', () => {
    it('returns empty array when outcomes data is undefined', async () => {
      mockExecuteQuery.mockResolvedValue({
        group: {
          _id: '1',
          description: 'Test',
          title: 'Test',
          outcomesCount: 0,
          notImportedOutcomesCount: 0,
          outcomes: {
            pageInfo: {hasNextPage: false, endCursor: null},
            edges: undefined,
          },
        },
      } as any)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.outcomes).toEqual([])
      expect(result.current.outcomesCount).toBe(0)
    })

    it('returns false for hasNextPage when pageInfo is undefined', async () => {
      mockExecuteQuery.mockResolvedValue({
        group: {
          _id: '1',
          description: 'Test',
          title: 'Test',
          outcomesCount: 0,
          notImportedOutcomesCount: 0,
          outcomes: {
            pageInfo: undefined,
            edges: [],
          },
        },
      } as any)

      const {result} = renderHook(
        () =>
          useOutcomes({
            courseId: '123',
            groupId: '1',
          }),
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.hasNextPage).toBe(false)
      expect(result.current.endCursor).toBe(null)
    })
  })
})
