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
import {
  fetchModuleItemsHtml,
  fetchModuleItems,
  type ModuleId
} from '../utils/fetchModuleItems'

const courseId = '23'
const pageSize = 2

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

const createMockContainer = (moduleId: string) => {
  const div = document.createElement('div')
  div.id = `context_module_content_${moduleId}`
  document.body.appendChild(div)
}

Object.keys(modules).forEach((moduleId: string) => {
  createMockContainer(moduleId)

  fetchMock.mock(modules[moduleId].api, {
    body: modules[moduleId].items,
    headers: {
      link: modules[moduleId].link,
    },
  })
})

const badModule = {
  moduleId: '1086',
  api: '/courses/23/modules/1086/items_html?per_page=2',
  response: new Response('', {status: 500}),
}

fetchMock.mock(badModule.api, badModule.response)

createMockContainer(badModule.moduleId)

describe('fetchModuleItems utility', () => {
  afterEach(() => {
    fetchMock.resetHistory()
    Object.keys(modules).forEach((moduleId: string) => {
      const container = document.querySelector(`#context_module_content_${moduleId}`)
      if (container) {
        container.innerHTML = ''
      }
    })
  })

  describe('fetchModuleItems', () => {
    it('does nothing if no modules are provided', async () => {
      const callback = jest.fn()
      await fetchModuleItems(courseId, [], callback, pageSize)
      expect(callback).not.toHaveBeenCalled()
    })

    it('does nothing if the provided moduleIds not exist in the dom', async () => {
      await fetchModuleItems(courseId, ['noop'], jest.fn(), pageSize)
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('construct the api urls correctly', async () => {
      await fetchModuleItems(courseId, Object.keys(modules), jest.fn(), pageSize)
      const calls = fetchMock.calls()
      expect(calls[0][0]).toBe(`/courses/${courseId}/modules/1083/items_html?per_page=${pageSize}`)
      expect(calls[1][0]).toBe(`/courses/${courseId}/modules/1084/items_html?per_page=${pageSize}`)
      expect(calls[2][0]).toBe(`/courses/${courseId}/modules/1085/items_html?per_page=${pageSize}`)
    })

    it('fetches the items', async () => {
      await fetchModuleItems(courseId, Object.keys(modules), jest.fn(), pageSize)
      expect(fetchMock.calls()).toHaveLength(3)
    })

    describe('success responses', () => {
      it('set the htmls in the containers with the results', async () => {
        await fetchModuleItems(courseId, Object.keys(modules), jest.fn(), pageSize)
        Object.keys(modules).forEach(moduleId => {
          expect(document.querySelector(`#context_module_content_${moduleId}`)?.innerHTML)
            .toEqual(modules[moduleId].items)
        })
      })

      it("calls the callback for each module's items", async () => {
        const callback = jest.fn()
        await fetchModuleItems(courseId, Object.keys(modules), callback, pageSize)
        Object.keys(modules)
          .forEach(moduleId => expect(callback).toHaveBeenCalledWith(moduleId))
      })
    })

    describe('failed responses', () => {
      const badModuleId = badModule.moduleId

      it('does not set the htmls', async () => {
        await fetchModuleItems(courseId, [badModuleId], jest.fn(), pageSize)
        expect(document.querySelector(`#context_module_content_${badModuleId}`)?.innerHTML)
          .toContain('Items failed to load')
      })

      it('does not call the callback', async () => {
        const callback = jest.fn()
        await fetchModuleItems(courseId, [badModuleId], callback, pageSize)
        expect(callback).not.toHaveBeenCalled()
      })
    })

    describe('mixed responses', () => {
      const badModuleId = badModule.moduleId
      const goodModuleId = '1083'

      it('does set the html for successful responses', async () => {
        await fetchModuleItems(courseId, [badModuleId, goodModuleId], jest.fn(), pageSize)
        expect(document.querySelector(`#context_module_content_${goodModuleId}`)?.innerHTML)
          .toEqual(modules[goodModuleId].items)
        expect(document.querySelector(`#context_module_content_${badModuleId}`)?.innerHTML)
          .toContain('Items failed to load')
      })

      it('does call the callback for successful responses', async () => {
        const callback = jest.fn()
        await fetchModuleItems(courseId, [badModuleId, goodModuleId], callback, pageSize)
        expect(callback).toHaveBeenCalledWith(goodModuleId)
        expect(callback).not.toHaveBeenCalledWith(badModuleId)
      })
    })
  })

  describe('fetchModuleItemsHtml', () => {
    const moduleId = '1083'

    it('does nothing if the provided moduleId not exist in the dom', async () => {
      await fetchModuleItemsHtml(courseId, 'noop', jest.fn(), pageSize)
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('construct the api url correctly', async () => {
      await fetchModuleItemsHtml(courseId, moduleId, jest.fn(), pageSize)
      const calls = fetchMock.calls()
      expect(calls[0][0]).toBe(`/courses/${courseId}/modules/1083/items_html?per_page=${pageSize}`)
    })

    it('fetches the item', async () => {
      await fetchModuleItemsHtml(courseId, moduleId, jest.fn(), pageSize)
      expect(fetchMock.calls()).toHaveLength(1)
    })

    describe('success response', () => {
      it('set the htmls in the container with the result', async () => {
        await fetchModuleItemsHtml(courseId, moduleId, jest.fn(), pageSize)
        expect(document.querySelector(`#context_module_content_${moduleId}`)?.innerHTML)
          .toEqual(modules[moduleId].items)
      })

      it("calls the callback for the module's item", async () => {
        const callback = jest.fn()
        await fetchModuleItemsHtml(courseId, moduleId, callback, pageSize)
        expect(callback).toHaveBeenCalledWith(moduleId)
      })
    })

    describe('failed response', () => {
      const badModuleId = badModule.moduleId

      it('does not set the html', async () => {
        await fetchModuleItemsHtml(courseId, badModuleId, jest.fn(), pageSize)
        expect(document.querySelector(`#context_module_content_${badModuleId}`)?.innerHTML)
          .toContain('Items failed to load')
      })

      it('does not call the callback', async () => {
        const callback = jest.fn()
        await fetchModuleItemsHtml(courseId, badModuleId, callback, pageSize)
        expect(callback).not.toHaveBeenCalled()
      })
    })
  })
})
