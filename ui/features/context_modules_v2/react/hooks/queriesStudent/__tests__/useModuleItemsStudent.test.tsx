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

import {useModuleItemsStudent} from '../useModuleItemsStudent'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'

const mockModuleItems = [
  {_id: 'item1', id: '1', url: 'https://example.com/item1', indent: 0},
  {_id: 'item2', id: '2', url: 'https://example.com/item2', indent: 1},
]
const mockItemsGqlResponse = {
  legacyNode: {
    moduleItems: mockModuleItems,
  },
}
const moduleId = '123'
const errorMsg = 'Test error'
const queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})

const renderUseModuleItemsStudentHook = (moduleId: string) =>
  renderHook(() => useModuleItemsStudent(moduleId, true), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })

const server = setupServer()

describe('useModuleItemsStudent', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })
  afterAll(() => server.close())

  it('should in error state if gql query throw exception', async () => {
    server.use(
      graphql.query('GetModuleItemsStudentQuery', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result} = renderUseModuleItemsStudentHook(moduleId)

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should in error state if the result contains error', async () => {
    server.use(
      graphql.query('GetModuleItemsStudentQuery', () => {
        return HttpResponse.json({
          data: {errors: [{message: errorMsg}]},
        })
      }),
    )

    const {result} = renderUseModuleItemsStudentHook(moduleId)

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should map the data pages correctly', async () => {
    server.use(
      graphql.query('GetModuleItemsStudentQuery', ({variables}) => {
        expect(variables.moduleId).toBe(moduleId)
        return HttpResponse.json({
          data: {legacyNode: mockItemsGqlResponse.legacyNode},
        })
      }),
    )

    const {result} = renderUseModuleItemsStudentHook(moduleId)

    await waitFor(() =>
      expect(result.current.data).toEqual({
        moduleItems: mockModuleItems.map((item, index) => ({
          ...item,
          moduleId,
          index,
        })),
      }),
    )
  })

  it('should set edges to empty array if edges is undefined', async () => {
    server.use(
      graphql.query('GetModuleItemsStudentQuery', () => {
        return HttpResponse.json({
          data: {legacyNode: {moduleItems: undefined}},
        })
      }),
    )

    const {result} = renderUseModuleItemsStudentHook(moduleId)

    await waitFor(() => {
      expect(result.current.data).toEqual({moduleItems: []})
    })
  })
})
