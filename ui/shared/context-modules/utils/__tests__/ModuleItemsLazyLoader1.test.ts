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
  ModuleItemsLazyLoader,
  type ModuleId,
  type ModuleItemsCallback,
  DEFAULT_PAGE,
} from '../ModuleItemsLazyLoader'
import {ModuleItemsStore} from '@canvas/context-modules/utils/ModuleItemsStore'

// @ts-expect-error
global.IS_REACT_ACT_ENVIRONMENT = true

const courseId = '23'
const pageSize = 2
const accountId = '3'
const userId = '4'

const modules: Record<ModuleId, {items: string; api: string; link: string}> = {
  '1083': {
    items: '<ul><li id="17"></li><li id="18"></li></ul>',
    api: '/courses/23/modules/1083/items_html?page=1&per_page=2',
    link: '</courses/23/modules/1083/items_html?page=1&per_page=2>; rel="current",</courses/23/modules/1083/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1083/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1083/items_html?page=2&per_page=2>; rel="last"',
  },
  '1084': {
    items: '<ul><li id="19"></li><li id="20"></li></ul>',
    api: '/courses/23/modules/1084/items_html?page=1&per_page=2',
    link: '</courses/23/modules/1084/items_html?page=1&per_page=2>; rel="current",</courses/23/modules/1084/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1084/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1084/items_html?page=2&per_page=2>; rel="last"',
  },
  '1085': {
    items: '<ul><li id="21"></li><li id="22"></li></ul>',
    api: '/courses/23/modules/1085/items_html?page=1&per_page=2',
    link: '</courses/23/modules/1085/items_html?page=1&per_page=2>; rel="current",</courses/23/modules/1085/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1085/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1085/items_html?page=2&per_page=2>; rel="last"',
  },
}

Object.keys(modules).forEach((moduleId: string) => {
  fetchMock.mock(modules[moduleId].api, {
    body: modules[moduleId].items,
    headers: {
      link: modules[moduleId].link,
    },
  })
  fetchMock.mock(`/courses/${courseId}/modules/${moduleId}/items_html?no_pagination=1`, 200)
})

const createMockContainer = (moduleId: string) => {
  const div = document.createElement('div')
  div.id = `context_module_content_${moduleId}`
  const footer = document.createElement('footer')
  footer.className = 'footer'
  div.appendChild(footer)
  document.body.appendChild(div)
}
const badModule = {
  moduleId: '1086',
  api: '/courses/23/modules/1086/items_html?page=1&per_page=2',
  response: new Response('', {status: 500}),
}

fetchMock.mock(badModule.api, badModule.response)

createMockContainer(badModule.moduleId)

let moduleItemsLazyLoader: ModuleItemsLazyLoader
let itemsCallback: ModuleItemsCallback
const mockStore = new ModuleItemsStore(courseId, accountId, userId)

describe('fetchModuleItems utility', () => {
  beforeEach(() => {
    itemsCallback = jest.fn()
    moduleItemsLazyLoader = new ModuleItemsLazyLoader(courseId, itemsCallback, mockStore, pageSize)

    document.body.innerHTML = ''
    Object.keys(modules).forEach((moduleId: string) => {
      createMockContainer(moduleId)
    })
    createMockContainer(badModule.moduleId)
  })

  afterEach(() => {
    fetchMock.resetHistory()
    Object.keys(modules).forEach((moduleId: string) => {
      const container = document.querySelector(`#context_module_content_${moduleId}`)
      if (container) {
        container.innerHTML = ''
      }
    })
    jest.restoreAllMocks()
  })

  describe('fetchModuleItems', () => {
    it('does nothing if no modules are provided', async () => {
      await moduleItemsLazyLoader.fetchModuleItems([])
      expect(itemsCallback).not.toHaveBeenCalled()
    })

    it('does nothing if the provided moduleIds not exist in the dom', async () => {
      await moduleItemsLazyLoader.fetchModuleItems(['noop'])
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('construct the api urls correctly', async () => {
      await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
      const calls = fetchMock.calls()
      expect(calls[0][0]).toBe(
        `/courses/${courseId}/modules/1083/items_html?page=1&per_page=${pageSize}`,
      )
      expect(calls[1][0]).toBe(
        `/courses/${courseId}/modules/1084/items_html?page=1&per_page=${pageSize}`,
      )
      expect(calls[2][0]).toBe(
        `/courses/${courseId}/modules/1085/items_html?page=1&per_page=${pageSize}`,
      )
    })

    it('fetches the items', async () => {
      await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
      expect(fetchMock.calls()).toHaveLength(3)
    })

    describe('success responses', () => {
      it('set the html in the containers with the results', async () => {
        await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
        Object.keys(modules).forEach(moduleId => {
          expect(
            document.querySelector(`#context_module_content_${moduleId} ul`)?.outerHTML,
          ).toEqual(modules[moduleId].items)
        })
      })

      it("calls the callback for each module's items", async () => {
        await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
        Object.keys(modules).forEach(moduleId =>
          expect(itemsCallback).toHaveBeenCalledWith(moduleId),
        )
      })
    })

    describe('failed responses', () => {
      const badModuleId = badModule.moduleId

      it('handles the error appropriately', async () => {
        // We know the module will fail to load because we've mocked the fetch to fail
        await moduleItemsLazyLoader.fetchModuleItems([badModuleId])

        // The error is handled by the renderError method which calls ModuleItemsLazyLoader.loadingData.getModuleRoot
        // We can verify the error handling by checking that the callback wasn't called
        expect(itemsCallback).not.toHaveBeenCalled()

        // Also verify the module content still exists but wasn't modified
        const moduleContent = document.querySelector(`#context_module_content_${badModuleId}`)
        expect(moduleContent).toBeTruthy()
        expect(moduleContent?.innerHTML).toContain('<footer class="footer"></footer>')
      })

      it('does not call the callback', async () => {
        await moduleItemsLazyLoader.fetchModuleItems([badModuleId])
        expect(itemsCallback).not.toHaveBeenCalled()
      })
    })

    describe('mixed responses', () => {
      const badModuleId = badModule.moduleId
      const goodModuleId = '1083'

      it('does set the html for successful responses', async () => {
        const callback = () => {
          expect(
            document.querySelector(`#context_module_content_${goodModuleId} ul`)?.outerHTML,
          ).toEqual(modules[goodModuleId].items)
          expect(
            document.querySelector(`#context_module_content_${badModuleId}`)?.outerHTML,
          ).toContain('Items failed to load')
        }
        const moduleItemsLazyLoader = new ModuleItemsLazyLoader(
          courseId,
          callback,
          mockStore,
          pageSize,
        )
        await moduleItemsLazyLoader.fetchModuleItems([badModuleId, goodModuleId])
      })

      it('does call the callback for successful responses', async () => {
        await moduleItemsLazyLoader.fetchModuleItems([badModuleId, goodModuleId])
        expect(itemsCallback).toHaveBeenCalledWith(goodModuleId)
        expect(itemsCallback).not.toHaveBeenCalledWith(badModuleId)
      })
    })
  })
})
