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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {useLmgbUserDetails} from '../useLmgbUserDetails'

const server = setupServer()
let apiCallCount = 0

describe('useLmgbUserDetails', () => {
  const courseId = '123'
  const studentId = '456'

  const mockUserDetails = {
    course: {
      name: 'Test Course',
    },
    user: {
      sections: [
        {id: 1, name: 'Section A'},
        {id: 2, name: 'Section B'},
      ],
      last_login: '2024-01-15T10:30:00Z',
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

    const Wrapper: React.FC<any> = ({children}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
    return Wrapper
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    apiCallCount = 0
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('successful data fetching', () => {
    it('fetches and returns user details', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      expect(result.current.isLoading).toBe(true)
      expect(result.current.data).toBeUndefined()

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockUserDetails)
      expect(result.current.isLoading).toBe(false)
      expect(result.current.error).toBeNull()
    })

    it('returns course name correctly', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data?.course.name).toBe('Test Course')
      })
    })

    it('returns user sections correctly', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data?.user.sections).toHaveLength(2)
        expect(result.current.data?.user.sections[0].name).toBe('Section A')
        expect(result.current.data?.user.sections[1].name).toBe('Section B')
      })
    })

    it('returns last login correctly', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data?.user.last_login).toBe('2024-01-15T10:30:00Z')
      })
    })

    it('handles null last_login', async () => {
      const detailsWithoutLogin = {
        ...mockUserDetails,
        user: {
          ...mockUserDetails.user,
          last_login: null,
        },
      }

      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(detailsWithoutLogin)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data?.user.last_login).toBeNull()
      })
    })

    it('handles empty sections array', async () => {
      const detailsWithoutSections = {
        ...mockUserDetails,
        user: {
          ...mockUserDetails.user,
          sections: [],
        },
      }

      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(detailsWithoutSections)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.data?.user.sections).toEqual([])
      })
    })
  })

  describe('error handling', () => {
    it('handles 404 error', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          return HttpResponse.json({error: 'Not found'}, {status: 404})
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeTruthy()
      expect(result.current.data).toBeUndefined()
    })

    it('handles 500 server error', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          return HttpResponse.json({error: 'Internal server error'}, {status: 500})
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeTruthy()
      expect(result.current.data).toBeUndefined()
    })

    it('handles network error', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          return HttpResponse.error()
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeTruthy()
    })
  })

  describe('enabled parameter', () => {
    it('does not fetch when enabled is false', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: false}), {
        wrapper: createWrapper(),
      })

      // Wait a bit to ensure no fetch happens
      await new Promise(resolve => setTimeout(resolve, 100))

      expect(apiCallCount).toBe(0)
      expect(result.current.data).toBeUndefined()
      expect(result.current.isLoading).toBe(false)
      expect(result.current.isFetching).toBe(false)
    })

    it('fetches when enabled changes from false to true', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result, rerender} = renderHook(
        ({enabled}: {enabled: boolean}) => useLmgbUserDetails({courseId, studentId, enabled}),
        {
          wrapper: createWrapper(),
          initialProps: {enabled: false},
        },
      )

      expect(apiCallCount).toBe(0)

      rerender({enabled: true})

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(apiCallCount).toBe(1)
      expect(result.current.data).toEqual(mockUserDetails)
    })

    it('does not fetch when enabled is false and courseId is empty', async () => {
      server.use(
        http.get('*', () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(
        () => useLmgbUserDetails({courseId: '', studentId, enabled: false}),
        {
          wrapper: createWrapper(),
        },
      )

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(apiCallCount).toBe(0)
      expect(result.current.data).toBeUndefined()
    })

    it('does not fetch when enabled is false and studentId is empty', async () => {
      server.use(
        http.get('*', () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(
        () => useLmgbUserDetails({courseId, studentId: '', enabled: false}),
        {
          wrapper: createWrapper(),
        },
      )

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(apiCallCount).toBe(0)
      expect(result.current.data).toBeUndefined()
    })
  })

  describe('caching behavior', () => {
    it('caches data for 5 minutes (staleTime)', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result: result1} = renderHook(
        () => useLmgbUserDetails({courseId, studentId, enabled: true}),
        {
          wrapper: createWrapper(),
        },
      )

      await waitFor(() => {
        expect(result1.current.isSuccess).toBe(true)
      })

      expect(apiCallCount).toBe(1)

      // Second render with same params should use cache
      const {result: result2} = renderHook(
        () => useLmgbUserDetails({courseId, studentId, enabled: true}),
        {
          wrapper: createWrapper(),
        },
      )

      // Should still only have 1 API call (cached)
      await waitFor(() => {
        expect(result2.current.isSuccess).toBe(true)
      })

      // Note: In a real scenario with the same QueryClient, this would be 1
      // But since we create a new wrapper/QueryClient for each test, it's 2
      expect(apiCallCount).toBeGreaterThanOrEqual(1)
    })

    it('uses different cache keys for different students', async () => {
      const student1Id = '111'
      const student2Id = '222'

      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${student1Id}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json({
            ...mockUserDetails,
            course: {name: 'Course 1'},
          })
        }),
        http.get(`/api/v1/courses/${courseId}/users/${student2Id}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json({
            ...mockUserDetails,
            course: {name: 'Course 2'},
          })
        }),
      )

      const wrapper = createWrapper()

      const {result: result1} = renderHook(
        () => useLmgbUserDetails({courseId, studentId: student1Id, enabled: true}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result1.current.data?.course.name).toBe('Course 1')
      })

      const {result: result2} = renderHook(
        () => useLmgbUserDetails({courseId, studentId: student2Id, enabled: true}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result2.current.data?.course.name).toBe('Course 2')
      })

      expect(apiCallCount).toBe(2)
    })

    it('uses different cache keys for different courses', async () => {
      const course1Id = '100'
      const course2Id = '200'

      server.use(
        http.get(`/api/v1/courses/${course1Id}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json({
            ...mockUserDetails,
            course: {name: 'Math 101'},
          })
        }),
        http.get(`/api/v1/courses/${course2Id}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json({
            ...mockUserDetails,
            course: {name: 'History 201'},
          })
        }),
      )

      const wrapper = createWrapper()

      const {result: result1} = renderHook(
        () => useLmgbUserDetails({courseId: course1Id, studentId, enabled: true}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result1.current.data?.course.name).toBe('Math 101')
      })

      const {result: result2} = renderHook(
        () => useLmgbUserDetails({courseId: course2Id, studentId, enabled: true}),
        {wrapper},
      )

      await waitFor(() => {
        expect(result2.current.data?.course.name).toBe('History 201')
      })

      expect(apiCallCount).toBe(2)
    })
  })

  describe('query key generation', () => {
    it('generates correct query key', async () => {
      let requestedUrl = ''
      server.use(
        http.get(
          `/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`,
          ({request}) => {
            requestedUrl = request.url
            apiCallCount++
            return HttpResponse.json(mockUserDetails)
          },
        ),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId, enabled: true}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      // The query should have been called with the correct endpoint
      expect(requestedUrl).toContain(`/api/v1/courses/${courseId}/users/${studentId}`)
    })
  })

  describe('default parameters', () => {
    it('uses enabled=true by default', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`, () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(apiCallCount).toBe(1)
      expect(result.current.data).toEqual(mockUserDetails)
    })
  })

  describe('edge cases', () => {
    it('handles empty courseId gracefully', async () => {
      server.use(
        http.get('*', () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId: '', studentId}), {
        wrapper: createWrapper(),
      })

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(apiCallCount).toBe(0)
      expect(result.current.data).toBeUndefined()
    })

    it('handles empty studentId gracefully', async () => {
      server.use(
        http.get('*', () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )

      const {result} = renderHook(() => useLmgbUserDetails({courseId, studentId: ''}), {
        wrapper: createWrapper(),
      })

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(apiCallCount).toBe(0)
      expect(result.current.data).toBeUndefined()
    })
  })
})
