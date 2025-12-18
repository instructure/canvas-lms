/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import PerformanceControls from '../../PerformanceControls'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import store from '../index'
import type {CustomColumn} from '../../gradebook.d'
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(),
}))

const exampleCustomColumns: CustomColumn[] = [
  {
    hidden: false,
    id: '2401',
    position: 0,
    read_only: false,
    teacher_notes: false,
    title: 'Custom Column 1',
  },
  {
    hidden: false,
    id: '2402',
    position: 1,
    read_only: false,
    teacher_notes: false,
    title: 'Custom Column 2',
  },
]

describe('customColumnsState', () => {
  const url = '/api/v1/courses/*/custom_gradebook_columns'
  const dataUrl = '/api/v1/courses/*/custom_gradebook_columns/*/data'
  const server = setupServer(
    // Default handler for custom column data requests
    http.get(dataUrl, () => {
      return HttpResponse.json([])
    }),
  )
  const capturedRequests: any[] = []

  function getRequests() {
    return capturedRequests
  }

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequests.length = 0
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('sends a request to the custom columns url', async () => {
    server.use(
      http.get(url, async ({request}) => {
        capturedRequests.push({url: request.url})
        return HttpResponse.json([])
      }),
    )

    await store.getState().fetchCustomColumns()
    const requests = getRequests()
    expect(requests).toHaveLength(1)
  })

  describe('when sending the initial request', () => {
    it('sets the `per_page` parameter to the configured per page maximum', async () => {
      server.use(
        http.get(url, async ({request}) => {
          const url = new URL(request.url)
          const params = Object.fromEntries(url.searchParams.entries())
          capturedRequests.push({params})
          return HttpResponse.json([])
        }),
      )

      store.setState({
        performanceControls: new PerformanceControls({customColumnsPerPage: 45}),
      })
      await store.getState().fetchCustomColumns()
      const [{params}] = getRequests()
      expect(params.per_page).toStrictEqual('45')
    })
  })

  describe('when the first page resolves', () => {
    beforeEach(async () => {
      let requestCount = 0
      server.use(
        http.get(url, async ({request}) => {
          const url = new URL(request.url)
          const params = Object.fromEntries(url.searchParams.entries())
          const page = params.page || '1'

          capturedRequests.push({
            params,
            path: url.pathname,
            page,
          })

          requestCount++

          if (requestCount === 1) {
            // First page response with pagination links
            return HttpResponse.json(exampleCustomColumns.slice(0, 1), {
              headers: {
                Link: '<http://localhost/api/v1/courses/1/custom_gradebook_columns?page=1>; rel="first", <http://localhost/api/v1/courses/1/custom_gradebook_columns?page=2>; rel="next", <http://localhost/api/v1/courses/1/custom_gradebook_columns?page=3>; rel="last"',
              },
            })
          } else {
            // Subsequent pages
            return HttpResponse.json([])
          }
        }),
      )

      await store.getState().fetchCustomColumns()
    })

    it('sends a request for each additional page', () => {
      const pages = getRequests()
        .slice(1)
        .map(request => request.params.page)
      expect(pages).toStrictEqual(['2', '3'])
    })

    it('uses the same path for each page', () => {
      const [{path}] = getRequests()
      getRequests()
        .slice(1)
        .forEach(request => {
          expect(request.path).toStrictEqual(path)
        })
    })

    it('uses the same parameters for each page', () => {
      const [{params}] = getRequests()
      getRequests()
        .slice(1)
        .forEach(request => {
          const {page, ...pageParams} = request.params
          expect(pageParams).toStrictEqual(params)
        })
    })
  })

  describe('when all pages have resolved', () => {
    beforeEach(async () => {
      server.use(
        http.get(url, async ({request}) => {
          const url = new URL(request.url)
          const params = Object.fromEntries(url.searchParams.entries())
          const page = params.page || '1'

          if (page === '1') {
            return HttpResponse.json(exampleCustomColumns.slice(0, 1), {
              headers: {
                Link: '<http://localhost/api/v1/courses/1/custom_gradebook_columns?page=1>; rel="first", <http://localhost/api/v1/courses/1/custom_gradebook_columns?page=2>; rel="next", <http://localhost/api/v1/courses/1/custom_gradebook_columns?page=3>; rel="last"',
              },
            })
          } else if (page === '2') {
            return HttpResponse.json(exampleCustomColumns.slice(1, 2))
          } else if (page === '3') {
            return HttpResponse.json(exampleCustomColumns.slice(2, 3))
          }

          return HttpResponse.json([])
        }),
      )

      await store.getState().fetchCustomColumns()
    })

    it('includes the loaded custom columns when updating the gradebook', () => {
      expect(store.getState().customColumns).toStrictEqual(exampleCustomColumns)
    })
  })

  describe('if the first response does not link to the last page', () => {
    beforeEach(async () => {
      server.use(
        http.get(url, async ({request}) => {
          capturedRequests.push({url: request.url})
          // Response without pagination Link header
          return HttpResponse.json(exampleCustomColumns.slice(0, 1))
        }),
      )

      await store.getState().fetchCustomColumns()
    })

    it('does not send additional requests', () => {
      expect(getRequests()).toHaveLength(1)
    })
  })
})
