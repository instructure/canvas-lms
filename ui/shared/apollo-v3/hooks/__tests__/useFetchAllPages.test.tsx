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

import {renderHook, act} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {useLazyQuery} from '@apollo/client'
import {useFetchAllPages} from '../useFetchAllPages'

// Mock Apollo Client
jest.mock('@apollo/client', () => ({
  ...jest.requireActual('@apollo/client'),
  useLazyQuery: jest.fn(),
}))

const mockUseLazyQuery = useLazyQuery as jest.MockedFunction<typeof useLazyQuery>

describe('useFetchAllPages', () => {
  // Mock query - not using gql tag to avoid GraphQL codegen validation
  const TEST_QUERY = {
    kind: 'Document',
    definitions: [],
  } as any

  const mockGetPageInfo = (data: any) => data?.items?.pageInfo

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('single page fetch', () => {
    it('should fetch and return single page of data', async () => {
      const mockData = {
        items: {
          nodes: [{id: '1', name: 'Item 1'}],
          pageInfo: {hasNextPage: false, endCursor: null},
        },
      }

      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: mockData,
        error: undefined,
      })

      const mockFetchMore = jest.fn()

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: mockData, loading: false, error: undefined, fetchMore: mockFetchMore},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      const [fetchAll, state] = result.current

      expect(state.loading).toBe(false)
      expect(state.data).toBe(mockData)

      await act(async () => {
        await fetchAll({variables: {testVar: 'test'}})
      })

      await waitFor(() => {
        const [, newState] = result.current
        expect(newState.loading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalledTimes(1)
      expect(mockExecuteQuery).toHaveBeenCalledWith({
        variables: {testVar: 'test', after: null},
      })
      expect(mockFetchMore).not.toHaveBeenCalled()
    })
  })

  describe('multi-page fetch', () => {
    it('should fetch all pages sequentially using fetchMore', async () => {
      const page1Data = {
        items: {
          nodes: [{id: '1', name: 'Item 1'}],
          pageInfo: {hasNextPage: true, endCursor: 'cursor1'},
        },
      }

      const page2Data = {
        items: {
          nodes: [
            {id: '1', name: 'Item 1'},
            {id: '2', name: 'Item 2'},
          ],
          pageInfo: {hasNextPage: true, endCursor: 'cursor2'},
        },
      }

      const page3Data = {
        items: {
          nodes: [
            {id: '1', name: 'Item 1'},
            {id: '2', name: 'Item 2'},
            {id: '3', name: 'Item 3'},
          ],
          pageInfo: {hasNextPage: false, endCursor: null},
        },
      }

      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: page1Data,
        error: undefined,
      })

      const mockFetchMore = jest
        .fn()
        .mockResolvedValueOnce({data: page2Data})
        .mockResolvedValueOnce({data: page3Data})

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: page3Data, loading: false, error: undefined, fetchMore: mockFetchMore},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll({variables: {testVar: 'test'}})
      })

      await waitFor(() => {
        const [, state] = result.current
        expect(state.loading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalledTimes(1)
      expect(mockExecuteQuery).toHaveBeenCalledWith({
        variables: {testVar: 'test', after: null},
      })
      expect(mockFetchMore).toHaveBeenCalledTimes(2)
      expect(mockFetchMore).toHaveBeenNthCalledWith(1, {variables: {after: 'cursor1'}})
      expect(mockFetchMore).toHaveBeenNthCalledWith(2, {variables: {after: 'cursor2'}})
    })

    it('should handle Apollo cache merging automatically', async () => {
      // This test verifies that we're using Apollo's cache merging
      // by relying on fetchMore instead of manual merging
      const page1 = [{id: '1', name: 'Item 1'}]
      const page2 = [{id: '2', name: 'Item 2'}]

      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: page1,
            pageInfo: {hasNextPage: true, endCursor: 'cursor1'},
          },
        },
        error: undefined,
      })

      // Apollo's cache will have merged the nodes by the time fetchMore resolves
      const mockFetchMore = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: [...page1, ...page2], // Simulating Apollo's cache merge
            pageInfo: {hasNextPage: false, endCursor: null},
          },
        },
      })

      const finalData = {
        items: {
          nodes: [...page1, ...page2],
          pageInfo: {hasNextPage: false, endCursor: null},
        },
      }

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: finalData, loading: false, error: undefined, fetchMore: mockFetchMore},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        const [, state] = result.current
        expect(state.loading).toBe(false)
      })

      const [, finalState] = result.current
      expect(finalState.data?.items.nodes).toEqual([...page1, ...page2])
    })
  })

  describe('loading state', () => {
    it('should set loading to true while fetching', async () => {
      const mockExecuteQuery = jest.fn().mockImplementation(
        () =>
          new Promise(resolve =>
            setTimeout(
              () =>
                resolve({
                  data: {
                    items: {
                      nodes: [{id: '1', name: 'Item 1'}],
                      pageInfo: {hasNextPage: false, endCursor: null},
                    },
                  },
                  error: undefined,
                }),
              100,
            ),
          ),
      )

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: undefined, loading: false, error: undefined, fetchMore: jest.fn()},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      expect(result.current[1].loading).toBe(false)

      act(() => {
        const [fetchAll] = result.current
        fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(true)
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })
    })
  })

  describe('error handling', () => {
    it('should handle query errors', async () => {
      const testError = new Error('Query failed')
      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: undefined,
        error: testError,
      })

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: undefined, loading: false, error: undefined, fetchMore: jest.fn()},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      const [, finalState] = result.current
      expect(finalState.error).toBe(testError)
    })

    it('should handle missing data error', async () => {
      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: null,
        error: undefined,
      })

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: null, loading: false, error: undefined, fetchMore: jest.fn()},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      const [, finalState] = result.current
      expect(finalState.error).toBeDefined()
      expect(finalState.error?.message).toBe('No data returned from query')
    })

    it('should handle missing pageInfo error', async () => {
      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: [{id: '1', name: 'Item 1'}],
            // Missing pageInfo
          },
        },
        error: undefined,
      })

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: undefined, loading: false, error: undefined, fetchMore: jest.fn()},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      const [, finalState] = result.current
      expect(finalState.error).toBeDefined()
      expect(finalState.error?.message).toBe('Could not extract pageInfo from query result')
    })

    it('should handle errors from useLazyQuery hook', async () => {
      const apolloError = new Error('Apollo error')
      const mockExecuteQuery = jest.fn()

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: undefined, loading: false, error: apolloError, fetchMore: jest.fn()},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      const [, state] = result.current
      expect(state.error).toBe(apolloError)
    })

    it('should stop fetching on error in fetchMore', async () => {
      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: [{id: '1', name: 'Item 1'}],
            pageInfo: {hasNextPage: true, endCursor: 'cursor1'},
          },
        },
        error: undefined,
      })

      const mockFetchMore = jest.fn().mockResolvedValue({
        data: undefined,
        error: new Error('Second page failed'),
      })

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: undefined, loading: false, error: undefined, fetchMore: mockFetchMore},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      const [, finalState] = result.current
      expect(finalState.error).toBeDefined()
      expect(mockExecuteQuery).toHaveBeenCalledTimes(1)
      expect(mockFetchMore).toHaveBeenCalledTimes(1)
    })
  })

  describe('variables handling', () => {
    it('should pass variables to query and preserve them in fetchMore', async () => {
      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: [{id: '1'}],
            pageInfo: {hasNextPage: true, endCursor: 'cursor1'},
          },
        },
        error: undefined,
      })

      const mockFetchMore = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: [{id: '1'}, {id: '2'}],
            pageInfo: {hasNextPage: false, endCursor: null},
          },
        },
      })

      const finalData = {
        items: {
          nodes: [{id: '1'}, {id: '2'}],
          pageInfo: {hasNextPage: false, endCursor: null},
        },
      }

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: finalData, loading: false, error: undefined, fetchMore: mockFetchMore},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll({
          variables: {
            userId: '123',
            contextCode: 'course_456',
            recipientIds: ['1', '2', '3'],
          },
        })
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalledWith({
        variables: {
          userId: '123',
          contextCode: 'course_456',
          recipientIds: ['1', '2', '3'],
          after: null,
        },
      })
      expect(mockFetchMore).toHaveBeenCalledWith({
        variables: {after: 'cursor1'},
      })
    })

    it('should work without variables', async () => {
      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: {
          items: {
            nodes: [{id: '1'}],
            pageInfo: {hasNextPage: false, endCursor: null},
          },
        },
        error: undefined,
      })

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: undefined, loading: false, error: undefined, fetchMore: jest.fn()},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: mockGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      expect(mockExecuteQuery).toHaveBeenCalledWith({
        variables: {after: null},
      })
    })
  })

  describe('complex data structures', () => {
    it('should handle nested data structures', async () => {
      const customGetPageInfo = (data: any) => data?.legacyNode?.recipientsObservers?.pageInfo

      const mockExecuteQuery = jest.fn().mockResolvedValue({
        data: {
          legacyNode: {
            id: 'user1',
            recipientsObservers: {
              nodes: [{id: '1', name: 'Observer 1'}],
              pageInfo: {hasNextPage: true, endCursor: 'cursor1'},
            },
          },
        },
        error: undefined,
      })

      const mockFetchMore = jest.fn().mockResolvedValue({
        data: {
          legacyNode: {
            id: 'user1',
            recipientsObservers: {
              nodes: [
                {id: '1', name: 'Observer 1'},
                {id: '2', name: 'Observer 2'},
              ],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
          },
        },
      })

      const finalData = {
        legacyNode: {
          id: 'user1',
          recipientsObservers: {
            nodes: [
              {id: '1', name: 'Observer 1'},
              {id: '2', name: 'Observer 2'},
            ],
            pageInfo: {hasNextPage: false, endCursor: null},
          },
        },
      }

      mockUseLazyQuery.mockReturnValue([
        mockExecuteQuery,
        {data: finalData, loading: false, error: undefined, fetchMore: mockFetchMore},
      ] as any)

      const {result} = renderHook(() =>
        useFetchAllPages(TEST_QUERY, {
          getPageInfo: customGetPageInfo,
        }),
      )

      await act(async () => {
        const [fetchAll] = result.current
        await fetchAll()
      })

      await waitFor(() => {
        expect(result.current[1].loading).toBe(false)
      })

      const [, finalState] = result.current
      expect(finalState.data?.legacyNode.recipientsObservers.nodes).toHaveLength(2)
      expect(mockFetchMore).toHaveBeenCalledTimes(1)
    })
  })
})
