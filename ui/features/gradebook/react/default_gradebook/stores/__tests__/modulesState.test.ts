// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
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
const exampleData = {
  contextModules: [{id: '2601'}, {id: '2602 '}, {id: '2603'}],
}

describe('modulesState', () => {
  const url = '/api/v1/courses/1/modules'
  const capturedRequests: any[] = []

  const server = setupServer()

  function getRequests() {
    return capturedRequests.filter(request => request.url.includes('/api/v1/courses/1/modules'))
  }

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    capturedRequests.length = 0
    store.setState({courseId: '1'})

    // Reset modules state
    store.setState({modules: [], isModulesLoading: false})
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('sends a request to the context modules url', async () => {
    server.use(
      http.get('/api/v1/courses/1/modules', async ({request}) => {
        const url = new URL(request.url)
        const params = Object.fromEntries(url.searchParams.entries())
        capturedRequests.push({url: request.url, params, path: url.pathname})
        return HttpResponse.json([])
      }),
    )

    await store.getState().fetchModules()
    const requests = getRequests()
    expect(requests).toHaveLength(1)
  })

  describe('when sending the initial request', () => {
    it('sets the `per_page` parameter to the configured per page maximum', async () => {
      server.use(
        http.get('/api/v1/courses/1/modules', async ({request}) => {
          const url = new URL(request.url)
          const params = Object.fromEntries(url.searchParams.entries())
          capturedRequests.push({url: request.url, params, path: url.pathname})
          return HttpResponse.json([])
        }),
      )

      store.setState({
        performanceControls: new PerformanceControls({contextModulesPerPage: 45}),
      })
      await store.getState().fetchModules()
      const [{params}] = getRequests()
      expect(params.per_page).toStrictEqual('45')
    })
  })

  describe('when pagination links are present', () => {
    it('fetches multiple pages and includes all modules', async () => {
      server.use(
        http.get('/api/v1/courses/1/modules', async ({request}) => {
          const url = new URL(request.url)
          const params = Object.fromEntries(url.searchParams.entries())
          const page = params.page || '1'
          capturedRequests.push({url: request.url, params, path: url.pathname})

          if (page === '1') {
            return HttpResponse.json(exampleData.contextModules.slice(0, 1), {
              headers: {
                Link: '</api/v1/courses/1/modules?page=1>; rel="first", </api/v1/courses/1/modules?page=2>; rel="next", </api/v1/courses/1/modules?page=3>; rel="last"',
              },
            })
          } else if (page === '2') {
            return HttpResponse.json(exampleData.contextModules.slice(1, 2), {
              headers: {
                Link: '</api/v1/courses/1/modules?page=1>; rel="first", </api/v1/courses/1/modules?page=1>; rel="prev", </api/v1/courses/1/modules?page=3>; rel="next", </api/v1/courses/1/modules?page=3>; rel="last"',
              },
            })
          } else if (page === '3') {
            return HttpResponse.json(exampleData.contextModules.slice(2, 3), {
              headers: {
                Link: '</api/v1/courses/1/modules?page=1>; rel="first", </api/v1/courses/1/modules?page=2>; rel="prev", </api/v1/courses/1/modules?page=3>; rel="last"',
              },
            })
          }
          return HttpResponse.json([])
        }),
      )

      await store.getState().fetchModules()

      // Check that multiple pages were requested
      const pages = getRequests().map(request => request.params.page || '1')
      expect(pages).toEqual(['1', '2', '3'])

      // Check that all modules were loaded
      expect(store.getState().modules).toEqual(exampleData.contextModules)
    })
  })

  describe('when no pagination links are present', () => {
    it('only sends one request', async () => {
      server.use(
        http.get('/api/v1/courses/1/modules', async ({request}) => {
          const url = new URL(request.url)
          const params = Object.fromEntries(url.searchParams.entries())
          capturedRequests.push({url: request.url, params, path: url.pathname})

          // Return single page without pagination links
          return HttpResponse.json(exampleData.contextModules.slice(0, 1))
        }),
      )

      await store.getState().fetchModules()
      expect(getRequests()).toHaveLength(1)
    })
  })
})
