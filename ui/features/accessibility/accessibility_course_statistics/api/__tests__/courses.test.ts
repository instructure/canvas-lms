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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {fetchCourses} from '../courses'
import {createMockCourses, createMockLinkHeaderString} from '../../__tests__/factories'

const server = setupServer()
const accountId = '123'

const baseParams = {
  accountId,
  sort: 'course_name',
  order: 'asc' as const,
  page: 1,
  search: '',
}

describe('fetchCourses', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  describe('request parameters', () => {
    it('sends sort and order params', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses({...baseParams, sort: 'sis_course_id', order: 'desc'})

      expect(params?.get('sort')).toBe('sis_course_id')
      expect(params?.get('order')).toBe('desc')
    })

    it('sends the correct page number', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses({...baseParams, page: 4})

      expect(params?.get('page')).toBe('4')
    })

    it('sends per_page=14', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses(baseParams)

      expect(params?.get('per_page')).toBe('14')
    })

    it('sends required include params', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses(baseParams)

      const include = params?.getAll('include[]')
      expect(include).toContain('total_students')
      expect(include).toContain('active_teachers')
      expect(include).toContain('subaccount')
      expect(include).toContain('term')
      expect(include).toContain('accessibility_course_statistic')
    })

    it('includes search_term when search is non-empty', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses({...baseParams, search: 'biology'})

      expect(params?.get('search_term')).toBe('biology')
    })

    it('omits search_term when search is empty', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses({...baseParams, search: ''})

      expect(params?.has('search_term')).toBe(false)
    })

    it('includes enrollment_term_id when provided', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses({...baseParams, enrollment_term_id: '42'})

      expect(params?.get('enrollment_term_id')).toBe('42')
    })

    it('omits enrollment_term_id when not provided', async () => {
      let params: URLSearchParams | undefined

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, ({request}) => {
          params = new URL(request.url).searchParams
          return HttpResponse.json([])
        }),
      )

      await fetchCourses(baseParams)

      expect(params?.has('enrollment_term_id')).toBe(false)
    })
  })

  describe('response handling', () => {
    it('returns courses from the response', async () => {
      const mockCourses = createMockCourses(3)

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () => HttpResponse.json(mockCourses)),
      )

      const result = await fetchCourses(baseParams)

      expect(result.courses).toEqual(mockCourses)
      expect(result.courses).toHaveLength(3)
    })

    it('returns empty array when API returns empty list', async () => {
      server.use(http.get(`/api/v1/accounts/${accountId}/courses`, () => HttpResponse.json([])))

      const result = await fetchCourses(baseParams)

      expect(result.courses).toEqual([])
    })

    it('parses pageCount from Link header last page', async () => {
      const mockCourses = createMockCourses(14)

      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () =>
          HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(7, accountId)},
          }),
        ),
      )

      const result = await fetchCourses(baseParams)

      expect(result.pageCount).toBe(7)
    })

    it('defaults pageCount to 1 when Link header is absent', async () => {
      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () =>
          HttpResponse.json(createMockCourses(5)),
        ),
      )

      const result = await fetchCourses(baseParams)

      expect(result.pageCount).toBe(1)
    })
  })

  describe('error handling', () => {
    it('returns empty courses and pageCount 1 for a 404 response', async () => {
      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () =>
          HttpResponse.json({errors: [{message: 'not found'}]}, {status: 404}),
        ),
      )

      const result = await fetchCourses({...baseParams, enrollment_term_id: 'nonexistent'})

      expect(result.courses).toEqual([])
      expect(result.pageCount).toBe(1)
    })

    it('re-throws non-404 errors', async () => {
      server.use(
        http.get(`/api/v1/accounts/${accountId}/courses`, () =>
          HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500}),
        ),
      )

      await expect(fetchCourses(baseParams)).rejects.toThrow()
    })
  })
})
