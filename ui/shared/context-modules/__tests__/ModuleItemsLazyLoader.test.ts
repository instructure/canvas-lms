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

import {waitFor} from '@testing-library/react'
import {screen} from '@testing-library/dom'
import fetchMock from 'fetch-mock'
import {ModuleItemsLazyLoader, type ModuleId} from '../utils/ModuleItemsLazyLoader'

const courseId = '23'
const pageSize = 2

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

describe('fetchModuleItems utility', () => {
  beforeEach(() => {
    moduleItemsLazyLoader = new ModuleItemsLazyLoader()
    moduleItemsLazyLoader.courseId = courseId
    moduleItemsLazyLoader.callback = jest.fn()
    moduleItemsLazyLoader.perPage = pageSize

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
  })

  describe('fetchModuleItems', () => {
    it('does nothing if no modules are provided', async () => {
      const callback = jest.fn()
      await moduleItemsLazyLoader.fetchModuleItems(courseId, [], callback, pageSize)
      expect(callback).not.toHaveBeenCalled()
    })

    it('does nothing if the provided moduleIds not exist in the dom', async () => {
      await moduleItemsLazyLoader.fetchModuleItems(courseId, ['noop'], jest.fn(), pageSize)
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('construct the api urls correctly', async () => {
      await moduleItemsLazyLoader.fetchModuleItems(
        courseId,
        Object.keys(modules),
        jest.fn(),
        pageSize,
      )
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
      await moduleItemsLazyLoader.fetchModuleItems(
        courseId,
        Object.keys(modules),
        jest.fn(),
        pageSize,
      )
      expect(fetchMock.calls()).toHaveLength(3)
    })

    describe('success responses', () => {
      it('set the html in the containers with the results', async () => {
        await moduleItemsLazyLoader.fetchModuleItems(
          courseId,
          Object.keys(modules),
          jest.fn(),
          pageSize,
        )
        Object.keys(modules).forEach(moduleId => {
          expect(
            document.querySelector(`#context_module_content_${moduleId} ul`)?.outerHTML,
          ).toEqual(modules[moduleId].items)
        })
      })

      it("calls the callback for each module's items", async () => {
        const callback = jest.fn()
        await moduleItemsLazyLoader.fetchModuleItems(
          courseId,
          Object.keys(modules),
          callback,
          pageSize,
        )
        Object.keys(modules).forEach(moduleId => expect(callback).toHaveBeenCalledWith(moduleId))
      })
    })

    describe('failed responses', () => {
      const badModuleId = badModule.moduleId

      it('does not set the html', async () => {
        await moduleItemsLazyLoader.fetchModuleItems(courseId, [badModuleId], jest.fn(), pageSize)
        await waitFor(() => {
          expect(
            document.querySelector(`#context_module_content_${badModuleId}`)?.innerHTML,
          ).toContain('Items failed to load')
        })
      })

      it('does not call the callback', async () => {
        const callback = jest.fn()
        await moduleItemsLazyLoader.fetchModuleItems(courseId, [badModuleId], callback, pageSize)
        expect(callback).not.toHaveBeenCalled()
      })
    })

    describe('mixed responses', () => {
      const badModuleId = badModule.moduleId
      const goodModuleId = '1083'

      it('does set the html for successful responses', async () => {
        await moduleItemsLazyLoader.fetchModuleItems(
          courseId,
          [badModuleId, goodModuleId],
          jest.fn(),
          pageSize,
        )
        await waitFor(() => {
          expect(
            document.querySelector(`#context_module_content_${goodModuleId} ul`)?.outerHTML,
          ).toEqual(modules[goodModuleId].items)
        })
        await waitFor(() => {
          expect(
            document.querySelector(`#context_module_content_${badModuleId}`)?.outerHTML,
          ).toContain('Items failed to load')
        })
      })

      it('does call the callback for successful responses', async () => {
        const callback = jest.fn()
        await moduleItemsLazyLoader.fetchModuleItems(
          courseId,
          [badModuleId, goodModuleId],
          callback,
          pageSize,
        )
        expect(callback).toHaveBeenCalledWith(goodModuleId)
        expect(callback).not.toHaveBeenCalledWith(badModuleId)
      })
    })
  })

  describe('fetchModuleItemsHtml', () => {
    const moduleId = '1083'

    it('does nothing if the provided moduleId not exist in the dom', async () => {
      await moduleItemsLazyLoader.fetchModuleItemsHtml('noop', 1)
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it('construct the api url correctly', async () => {
      // use page=2 here
      fetchMock.mock(
        `/courses/${courseId}/modules/${moduleId}/items_html?page=2&per_page=${pageSize}`,
        200,
      )
      await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 2)
      const calls = fetchMock.calls()
      expect(calls[0][0]).toBe(
        `/courses/${courseId}/modules/${moduleId}/items_html?page=2&per_page=${pageSize}`,
      )
    })

    it('fetches the item', async () => {
      await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1)
      expect(fetchMock.calls()).toHaveLength(1)
    })

    describe('success response', () => {
      it('set the htmls in the container with the result', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1)
        expect(document.querySelector(`#context_module_content_${moduleId} ul`)?.outerHTML).toEqual(
          modules[moduleId].items,
        )
      })

      it("calls the callback for the module's item", async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1)
        expect(moduleItemsLazyLoader.callback).toHaveBeenCalledWith(moduleId)
      })
    })

    describe('failed response', () => {
      const badModuleId = badModule.moduleId

      it('does not set the html', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        await waitFor(() => {
          expect(
            document.querySelector(`#context_module_content_${badModuleId}`)?.outerHTML,
          ).toContain('Items failed to load')
        })
      })

      it('does not call the callback', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        expect(moduleItemsLazyLoader.callback).not.toHaveBeenCalled()
      })

      it('retries on clicking the retry button', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        await waitFor(() => {
          expect(screen.getByTestId('retry-items-failed-to-load')).toBeInTheDocument()
        })
        expect(fetchMock.calls()).toHaveLength(1)
        const retryButton = screen.getByTestId('retry-items-failed-to-load').closest('button')
        retryButton?.click()
        expect(fetchMock.calls()).toHaveLength(2)
      })
    })

    describe('pagination', () => {
      it('renders the Pagination component if there are more than one page', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml('1083', 1)
        await waitFor(() => {
          expect(screen.getByTestId('module-1083-pagination')).toBeInTheDocument()
        })
      })

      it('does not render the Pagination component if there is only one page', async () => {
        fetchMock.mock('/courses/23/modules/1083/items_html?page=1&per_page=10', {
          body: modules['1083'].items,
        })
        await moduleItemsLazyLoader.fetchModuleItemsHtml('1083', 1)
        expect(document.querySelector(`#context_module_content_1083 ul`)?.outerHTML).toEqual(
          modules['1083'].items,
        )
        expect(screen.queryByTestId('module-1083-pagination')).not.toBeInTheDocument()
      })
    })
  })
})
