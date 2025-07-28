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

import {useCourseTeacher} from '../useCourseTeacher'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'

const mockCourseTeacherData = {
  name: 'Test Course',
  settings: {
    showStudentOnlyModuleId: 'mod_1',
    showTeacherOnlyModuleId: 'mod_2',
  },
}

const mockGqlResponse = {
  legacyNode: {
    name: mockCourseTeacherData.name,
    settings: mockCourseTeacherData.settings,
  },
}

const courseId = '123'
const errorMsg = 'Test error'
const queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})

const renderUseCourseTeacherHook = (courseId: string) =>
  renderHook(() => useCourseTeacher(courseId), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })

const server = setupServer()

describe('useCourseTeacher', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })
  afterAll(() => server.close())

  it('should be in error state if gql query throws exception', async () => {
    server.use(
      graphql.query('GetCourseTeacherQuery', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result} = renderUseCourseTeacherHook(courseId)

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should be in error state if the result contains error', async () => {
    server.use(
      graphql.query('GetCourseTeacherQuery', () => {
        return HttpResponse.json({
          data: {errors: [{message: errorMsg}]},
        })
      }),
    )

    const {result} = renderUseCourseTeacherHook(courseId)

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
      expect(result.current.error?.message).toContain(errorMsg)
    })
  })

  it('should map the data correctly for successful response', async () => {
    server.use(
      graphql.query('GetCourseTeacherQuery', ({variables}) => {
        expect(variables.courseId).toBe(courseId)
        return HttpResponse.json({
          data: {legacyNode: mockGqlResponse.legacyNode},
        })
      }),
    )

    const {result} = renderUseCourseTeacherHook(courseId)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual(mockCourseTeacherData)
    })
  })

  it('should handle undefined data in the response', async () => {
    server.use(
      graphql.query('GetCourseTeacherQuery', () => {
        return HttpResponse.json({
          data: {legacyNode: null},
        })
      }),
    )

    const {result} = renderUseCourseTeacherHook(courseId)

    await waitFor(() => {
      expect(result.current.data).toEqual({
        name: undefined,
      })
    })
  })

  it('should pass the courseId to the query', async () => {
    let capturedVariables: any = null
    server.use(
      graphql.query('GetCourseTeacherQuery', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json({
          data: {legacyNode: mockGqlResponse.legacyNode},
        })
      }),
    )

    renderUseCourseTeacherHook(courseId)

    await waitFor(() => {
      expect(capturedVariables).toEqual({courseId})
    })
  })
})
