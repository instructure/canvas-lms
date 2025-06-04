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

import {useModulesStudent} from '../useModulesStudent'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'

const node1 = {
  id: '1',
  name: 'Module 1',
  position: 1,
  published: true,
}

const node2 = {
  id: '2',
  name: 'Module 2',
  position: 2,
  published: true,
}

const endPageInfo = {
  hasNextPage: false,
  endCursor: null,
}

const nextPageInfo = {
  hasNextPage: true,
  endCursor: 'cursor1',
}

const mockGqlResponseFinalPage = {
  legacyNode: {
    modulesConnection: {
      edges: [
        {
          node: node2,
        },
      ],
      pageInfo: endPageInfo,
    },
  },
}

const mockGqlResponseWithNextPage = {
  legacyNode: {
    modulesConnection: {
      edges: [
        {
          node: node1,
        },
      ],
      pageInfo: nextPageInfo,
    },
  },
}

const courseId = '123'
const errorMsg = 'Test error'
const queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})

const server = setupServer()

const renderUseModulesStudentHook = (courseId: string) =>
  renderHook(() => useModulesStudent(courseId), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })

describe('useModulesStudent', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })
  afterAll(() => server.close())

  it('should map the data pages correctly', async () => {
    server.use(
      graphql.query('GetModulesStudentQuery', ({variables}) => {
        expect(variables.courseId).toBe(courseId)
        return HttpResponse.json({
          data: {legacyNode: {...mockGqlResponseFinalPage.legacyNode}},
        })
      }),
    )

    const {result} = renderUseModulesStudentHook(courseId)

    expect(result.current.isLoading).toBe(true)
    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.data?.pages).toEqual([{modules: [{...node2}], pageInfo: endPageInfo}])
  })

  it('should query for next page', async () => {
    server.use(
      graphql.query('GetModulesStudentQuery', ({variables}) => {
        return HttpResponse.json({
          data: {
            legacyNode: variables.cursor
              ? mockGqlResponseFinalPage.legacyNode
              : mockGqlResponseWithNextPage.legacyNode,
          },
        })
      }),
    )

    const {result} = renderUseModulesStudentHook(courseId)

    // Wait for initial loading to complete
    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    // Wait for fetchNextPage to complete and all pages to be loaded
    await waitFor(() => {
      expect(result.current.hasNextPage).toBe(false)
    })

    // Now check that we have both pages
    expect(result.current.data?.pages).toEqual([
      {modules: [{...node1}], pageInfo: nextPageInfo},
      {modules: [{...node2}], pageInfo: endPageInfo},
    ])
  })

  it('should in error state if gql query throw exception', async () => {
    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result} = renderUseModulesStudentHook(courseId)

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should in error state if the result contains error', async () => {
    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          data: {errors: [{message: errorMsg}]},
        })
      }),
    )

    const {result} = renderUseModulesStudentHook(courseId)

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should set edges to empty array if edges is undefined', async () => {
    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              modulesConnection: {
                edges: undefined,
                pageInfo: endPageInfo,
              },
            },
          },
        })
      }),
    )

    const {result} = renderUseModulesStudentHook(courseId)

    await waitFor(() => {
      expect(result.current.data?.pages).toEqual([{modules: [], pageInfo: endPageInfo}])
    })
  })

  it('should set page info with default end page values if endPageInfo is undefined', async () => {
    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              modulesConnection: {
                edges: [],
                pageInfo: undefined,
              },
            },
          },
        })
      }),
    )

    const {result} = renderUseModulesStudentHook(courseId)

    await waitFor(() => {
      expect(result.current.data?.pages).toEqual([{modules: [], pageInfo: endPageInfo}])
    })
  })
})
