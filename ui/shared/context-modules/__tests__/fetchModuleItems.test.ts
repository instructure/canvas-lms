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

import fetchMock from 'fetch-mock'
import parseLinkHeader, {type Links} from '@canvas/parse-link-header'
import {
  fetchItemsForModule,
  fetchModuleItems,
  type ModuleId,
  type ModuleItems,
  type ModuleItemFetchError,
} from '../utils/fetchModuleItems'

const modules: Record<ModuleId, {items: string; api: string; link: string}> = {
  '1083': {
    items: '<ul id="17"></ul><ul id="18"></ul>',
    api: '/courses/23/modules/1083/items_html?per_page=2',
    link: '</courses/23/modules/1083/items_html?per_page=2>; rel="current",</courses/23/modules/1083/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1083/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1083/items_html?page=2&per_page=2>; rel="last"',
  },
  '1084': {
    items: '<ul id="19"></ul><ul id="20"></ul>',
    api: '/courses/23/modules/1084/items_html?per_page=2',
    link: '</courses/23/modules/1084/items_html?per_page=2>; rel="current",</courses/23/modules/1084/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1084/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1084/items_html?page=2&per_page=2>; rel="last"',
  },
  '1085': {
    items: '<ul id="21"></ul><ul id="22"></ul>',
    api: '/courses/23/modules/1085/items_html?per_page=2',
    link: '</courses/23/modules/1085/items_html?per_page=2>; rel="current",</courses/23/modules/1085/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1085/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1085/items_html?page=2&per_page=2>; rel="last"',
  },
}

const badModule = {
  moduleId: '1086',
  api: '/courses/23/modules/1086/items_html?per_page=2',
  response: new Response('', {status: 500}),
}

describe('fetchModuleItems utility', () => {
  beforeAll(() => {
    fetchMock.mock(modules['1083'].api, {
      body: modules['1083'].items,
      headers: {
        link: modules['1083'].link,
      },
    })
    fetchMock.mock(modules['1084'].api, {
      body: modules['1084'].items,
      headers: {
        link: modules['1084'].link,
      },
    })
    fetchMock.mock(modules['1085'].api, {
      body: modules['1085'].items,
      headers: {
        link: modules['1085'].link,
      },
    })
    fetchMock.mock(badModule.api, badModule.response)
  })

  afterEach(() => {
    fetchMock.resetHistory()
  })

  describe('fetchItemsForModule', () => {
    it('fetches items for a module', async () => {
      const callback = jest.fn()
      await fetchItemsForModule('1083', modules['1083'].api, callback)
      expect(callback).toHaveBeenCalledWith(
        '1083',
        modules['1083'].items,
        parseLinkHeader(modules['1083'].link),
      )
    })

    it('handles fetch failures', async () => {
      const callback = jest.fn()
      await fetchItemsForModule(badModule.moduleId, badModule.api, callback)
      expect(callback).toHaveBeenCalledWith(badModule.moduleId, '', undefined, {
        moduleId: badModule.moduleId,
        error: expect.any(Error),
      })
    })
  })

  describe('fetchModuleItems', () => {
    it('fetches batches of items', async () => {
      await fetchModuleItems('23', ['1083', '1084', '1085'], () => {}, 2)
      expect(fetchMock.calls()).toHaveLength(3)
    })

    it("calls the callback for each module's items", async () => {
      const callback = jest.fn((moduleId: ModuleId, itemHTML: string, link?: Links) => {
        expect(itemHTML).toEqual(modules[moduleId].items)
        expect(link).toBeDefined()
        expect(link).toEqual(parseLinkHeader(modules[moduleId].link))
      })
      await fetchModuleItems('23', ['1083', '1084', '1085'], callback, 2)
      ;['1083', '1084', '1085'].forEach(id =>
        expect(callback).toHaveBeenCalledWith(
          id,
          modules[id].items,
          parseLinkHeader(modules[id].link),
        ),
      )
    })

    it('calls the callback with an error for a bad module', async () => {
      const callback = jest.fn(
        (moduleId: ModuleId, itemHTML: string, link?: Links, error?: ModuleItemFetchError) => {
          expect(moduleId).toEqual('1086')
          expect(itemHTML).toEqual('')
          expect(link).toBeUndefined()
          expect(error?.moduleId).toEqual('1086')
          expect(error?.error.message).toEqual(
            'doFetchApi received a bad response: 500 Internal Server Error',
          )
          expect(error?.error.response.status).toEqual(500)
        },
      )
      await fetchModuleItems('23', ['1086'], callback, 2)
      expect(callback).toHaveBeenCalled()
    })

    it('does nothing if no modules are provided', async () => {
      const callback = jest.fn()
      const result = await fetchModuleItems('23', [], callback, 2)
      expect(result).toEqual([])
      expect(callback).not.toHaveBeenCalled()
    })
  })
})
