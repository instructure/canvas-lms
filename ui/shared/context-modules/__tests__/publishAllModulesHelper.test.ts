/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {waitFor} from '@testing-library/dom'
import publishOneModuleHelperModule from '../utils/publishOneModuleHelper'

import publishAllModulesHelperModule from '../utils/publishAllModulesHelper'
import {initBody, makeModuleWithItems} from './testHelpers'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const {
  batchUpdateAllModulesApiCall,
  fetchAllItemPublishedStates,
  updateModulePendingPublishedStates,
  updateModulePublishedState,
  moduleIds,
} = {
  ...publishAllModulesHelperModule,
}

const {renderContextModulesPublishIcon} = {
  ...publishOneModuleHelperModule,
}

vi.mock('../utils/publishOneModuleHelper')

const server = setupServer()

describe('publishAllModulesHelper', () => {
  // Track captured request for verification
  let lastCapturedRequest: {method: string; path: string; body?: any} | null = null

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    lastCapturedRequest = null
    // Default handlers
    server.use(
      http.put('/api/v1/courses/:courseId/modules', async ({request}) => {
        const url = new URL(request.url)
        lastCapturedRequest = {
          method: 'PUT',
          path: url.pathname,
          body: await request.json(),
        }
        return HttpResponse.json({published: true})
      }),
      http.get('/api/v1/courses/:courseId/modules', ({request}) => {
        const url = new URL(request.url)
        lastCapturedRequest = {
          method: 'GET',
          path: url.pathname + url.search,
        }
        return HttpResponse.json([])
      }),
    )
    initBody()
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    document.body.innerHTML = ''
  })

  describe('batchUpdateAllModulesApiCall', () => {
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119], false)
      makeModuleWithItems(2, [217, 219], true)
    })

    it('PUTS the batch request', async () => {
      const publish = true
      const skipItems = true
      await batchUpdateAllModulesApiCall(1, publish, skipItems)

      await waitFor(() => {
        expect(lastCapturedRequest).not.toBeNull()
      })
      expect(lastCapturedRequest!.method).toBe('PUT')
      expect(lastCapturedRequest!.path).toBe('/api/v1/courses/1/modules')
      expect(lastCapturedRequest!.body).toEqual({
        module_ids: [1, 2],
        event: 'publish',
        skip_content_tags: skipItems,
        async: true,
      })
    })

    it('returns a rejected promise on error', async () => {
      server.use(
        http.put('/api/v1/courses/:courseId/modules', () => HttpResponse.error()),
      )
      await expect(batchUpdateAllModulesApiCall(2, true, true)).rejects.toThrow()
    })
  })

  describe('fetchAllItemPublishedStates', () => {
    let requestCount = 0
    let requestPaths: string[] = []

    beforeEach(() => {
      requestCount = 0
      requestPaths = []
      server.use(
        http.get('/api/v1/courses/:courseId/modules', ({request}) => {
          const url = new URL(request.url)
          requestCount++
          requestPaths.push(url.pathname + url.search)
          return HttpResponse.json([])
        }),
      )
    })

    it('GETs the module item states', async () => {
      fetchAllItemPublishedStates(7)
      await waitFor(() => {
        expect(requestCount).toBe(1)
      })
      expect(requestPaths[0]).toBe('/api/v1/courses/7/modules?include[]=items')
    })

    it('exhausts paginated responses', async () => {
      // Override with paginated response
      server.use(
        http.get('/api/v1/courses/:courseId/modules', ({request}) => {
          const url = new URL(request.url)
          requestCount++
          requestPaths.push(url.pathname + url.search)
          return HttpResponse.json(
            [{id: 1, published: true, items: []}],
            {headers: {Link: '</another/page>; rel="next"'}},
          )
        }),
        http.get('/another/page', ({request}) => {
          requestCount++
          requestPaths.push(new URL(request.url).pathname)
          return HttpResponse.json([])
        }),
      )

      fetchAllItemPublishedStates(7)
      await waitFor(() => expect(requestCount).toBe(2))
      expect(requestPaths[1]).toBe('/another/page')
    })

    it('returns a rejected promise on error', async () => {
      server.use(
        http.get('/api/v1/courses/:courseId/modules', () => HttpResponse.error()),
      )
      await expect(fetchAllItemPublishedStates(7)).rejects.toThrow()
    })
  })

  describe('updateModulePendingPublishedStates', () => {
    let updateModuleSpy: any
    let updateItemsSpy: any
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119], false)
      makeModuleWithItems(2, [217, 219], true)
    })
    afterEach(() => {
      updateModuleSpy?.mockRestore()
      updateItemsSpy?.mockRestore()
    })

    it('updates the modules and their items', () => {
      updateModuleSpy = vi.spyOn(publishAllModulesHelperModule, 'updateModulePublishedState')
      updateItemsSpy = vi.spyOn(publishOneModuleHelperModule, 'updateModuleItemsPublishedStates')
      const isPublishing = true
      updateModulePendingPublishedStates(isPublishing)
      expect(updateModuleSpy).toHaveBeenCalledTimes(2)
      expect(updateItemsSpy).toHaveBeenCalledTimes(2)
      expect(updateItemsSpy).toHaveBeenCalledWith(1, undefined, isPublishing)
    })
  })

  describe('updateModulePublishedState', () => {
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119], false)
      makeModuleWithItems(2, [217, 219], true)
    })

    it('updates the module', () => {
      const published = true
      const isPublishing = false
      updateModulePublishedState(1, published, isPublishing)
      expect(renderContextModulesPublishIcon).toHaveBeenCalledTimes(1)
      expect(renderContextModulesPublishIcon).toHaveBeenCalledWith('1', 1, published, isPublishing)
    })
  })

  describe('moduleIds', () => {
    it('extracts module ids from the erb generated dom elements', () => {
      document.body.innerHTML = `
      <div>
        <span id="a_module_17" class="context_module" data-module-id="17">module 17</span>
        <span id="b_module_19" class="context_module" data-module-id="19">module 19</span
        <span id="template_module" class="context_module" data-module-id="{{ id }}"></span
      `
      const mids = moduleIds()
      expect(mids).toStrictEqual([17, 19])
    })

    it('returns only unique its', () => {
      document.body.innerHTML = `
      <div>
        <span id="a_module_17" class="context_module" data-module-id="17">module 17</span>
        <span id="b_module_17" class="context_module" data-module-id="17">module 17 too</span
        <span id="template_module" class="context_module" data-module-id="{{ id }}"></span
      `
      const mids = moduleIds()
      expect(mids).toStrictEqual([17])
    })
  })
})
