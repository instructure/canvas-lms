/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import RequestDispatch, {
  DEFAULT_ACTIVE_REQUEST_LIMIT,
  MAX_ACTIVE_REQUEST_LIMIT,
  MIN_ACTIVE_REQUEST_LIMIT,
} from '../index'

describe('Shared > Network > RequestDispatch', () => {
  const TEST_URL = 'http://localhost/example'
  const server = setupServer()

  let dispatch: RequestDispatch

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    dispatch = new RequestDispatch({activeRequestLimit: 2})
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('#options', () => {
    describe('.activeRequestLimit', () => {
      it('is set to the given value', () => {
        const {options} = new RequestDispatch({activeRequestLimit: 4})
        expect(options.activeRequestLimit).toBe(4)
      })

      it(`defaults to ${DEFAULT_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new RequestDispatch()
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it(`clips values higher than ${MAX_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new RequestDispatch({activeRequestLimit: 101})
        expect(options.activeRequestLimit).toBe(MAX_ACTIVE_REQUEST_LIMIT)
      })

      it(`clips values lower than ${MIN_ACTIVE_REQUEST_LIMIT}`, () => {
        const {options} = new RequestDispatch({activeRequestLimit: 0})
        expect(options.activeRequestLimit).toBe(MIN_ACTIVE_REQUEST_LIMIT)
      })

      it('converts valid string numbers', () => {
        const {options} = new RequestDispatch({activeRequestLimit: '24'})
        expect(options.activeRequestLimit).toBe(24)
      })

      it('rejects invalid strings', () => {
        const {options} = new RequestDispatch({activeRequestLimit: 'invalid'})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it('rejects null', () => {
        const {options} = new RequestDispatch({activeRequestLimit: 'null'})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })

      it('rejects undefined', () => {
        const {options} = new RequestDispatch({activeRequestLimit: undefined})
        expect(options.activeRequestLimit).toBe(DEFAULT_ACTIVE_REQUEST_LIMIT)
      })
    })
  })

  describe('#getJSON()', () => {
    function getJSON(params: Record<string, unknown> = {}) {
      return dispatch.getJSON(TEST_URL, params)
    }

    it('sends a request for the resource', async () => {
      server.use(http.get(TEST_URL, () => HttpResponse.json({})))
      const result = await getJSON({})
      expect(result).toEqual({})
    })

    it('includes the given params in the request', async () => {
      server.use(
        http.get(TEST_URL, ({request}) => {
          const url = new URL(request.url)
          expect(url.searchParams.get('example')).toBe('true')
          return HttpResponse.json({})
        }),
      )
      await getJSON({example: true})
    })

    it('resolves with the data from the request', async () => {
      server.use(http.get(TEST_URL, () => HttpResponse.json({example: true})))
      const result = await getJSON({})
      expect(result).toEqual({example: true})
    })

    it('resolves when flooded with requests', async () => {
      let requestIndex = 0
      server.use(
        http.get(TEST_URL, () => {
          const index = requestIndex++
          return HttpResponse.json({requestIndex: index})
        }),
      )

      const requests = Array.from({length: 4}).map(() => getJSON({}))
      const results = await Promise.all(requests)
      expect(results).toHaveLength(4)
    })

    it('includes custom headers in the request', async () => {
      const customHeaders = {'X-Custom-Header': 'test-value', Authorization: 'Bearer token'}

      server.use(
        http.get(TEST_URL, ({request}) => {
          expect(request.headers.get('X-Custom-Header')).toBe('test-value')
          expect(request.headers.get('Authorization')).toBe('Bearer token')
          return HttpResponse.json({})
        }),
      )

      await dispatch.getJSON(TEST_URL, {}, customHeaders)
    })

    it('ignores invalid headers', async () => {
      server.use(
        http.get(TEST_URL, ({request}) => {
          expect(request.headers.get('X-Invalid-Header')).toBeNull()
          return HttpResponse.json({})
        }),
      )

      await dispatch.getJSON(TEST_URL, {}, null as any)
      await dispatch.getJSON(TEST_URL, {}, 'invalid' as any)
      await dispatch.getJSON(TEST_URL, {}, undefined)
    })
  })

  describe('#getDepaginated()', () => {
    function getDepaginated(
      params: Record<string, unknown> = {},
      pageCallback?: (data?: unknown) => void,
      pagesEnqueued?: (promises: Promise<unknown>[]) => void,
    ) {
      return dispatch.getDepaginated(TEST_URL, params, pageCallback, pagesEnqueued)
    }

    it('sends a request for the resource', async () => {
      server.use(http.get(TEST_URL, () => HttpResponse.json([])))
      const result = await getDepaginated()
      expect(result).toEqual([])
    })

    it('includes the given params in the request', async () => {
      server.use(
        http.get(TEST_URL, ({request}) => {
          const url = new URL(request.url)
          expect(url.searchParams.get('example')).toBe('true')
          return HttpResponse.json([])
        }),
      )
      await getDepaginated({example: true})
    })

    it('handles pagination with callbacks', async () => {
      const pageCallback = vi.fn()
      const pagesEnqueued = vi.fn()

      server.use(
        http.get(TEST_URL, ({request}) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page') || '1'

          if (page === '1') {
            return HttpResponse.json([{dataForPage: 1}], {
              headers: {
                Link: `<${TEST_URL}?page=2>; rel="next", <${TEST_URL}?page=3>; rel="last"`,
              },
            })
          } else if (page === '2') {
            return HttpResponse.json([{dataForPage: 2}])
          } else if (page === '3') {
            return HttpResponse.json([{dataForPage: 3}])
          }
          return HttpResponse.json([])
        }),
      )

      const result = await getDepaginated({}, pageCallback, pagesEnqueued)

      expect(result).toEqual([{dataForPage: 1}, {dataForPage: 2}, {dataForPage: 3}])
      expect(pageCallback).toHaveBeenCalledTimes(3)
      expect(pagesEnqueued).toHaveBeenCalled()
    })

    it('handles single page response', async () => {
      server.use(http.get(TEST_URL, () => HttpResponse.json([{example: true}])))
      const result = await getDepaginated()
      expect(result).toEqual([{example: true}])
    })

    it('handles response with invalid pagination header', async () => {
      server.use(
        http.get(TEST_URL, () =>
          HttpResponse.json([{example: true}], {
            headers: {
              Link: '<invalid>; rel="last"',
            },
          }),
        ),
      )
      const result = await getDepaginated()
      expect(result).toEqual([{example: true}])
    })

    it('includes custom headers in paginated requests', async () => {
      const customHeaders = {'X-Custom-Header': 'test-value'}

      server.use(
        http.get(TEST_URL, ({request}) => {
          expect(request.headers.get('X-Custom-Header')).toBe('test-value')
          return HttpResponse.json([{example: true}])
        }),
      )

      const result = await dispatch.getDepaginated(
        TEST_URL,
        {},
        undefined,
        undefined,
        customHeaders,
      )
      expect(result).toEqual([{example: true}])
    })
  })
})
