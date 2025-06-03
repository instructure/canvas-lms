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

import {waitFor, screen} from '@testing-library/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {ModuleItemsLazyLoader, type ModuleItemsCallback} from '../ModuleItemsLazyLoader'
import {ModuleItemsStore, PREFIX} from '../ModuleItemsStore'
import {moduleFromId} from '../showAllOrLess'
import {type ModuleId} from '../types'
import {ModuleItemLoadingData} from '../ModuleItemLoadingData'

// @ts-expect-error
global.IS_REACT_ACT_ENVIRONMENT = true

const courseId = '23'
const pageSize = 2
const accountId = '3'
const userId = '4'

// Define badModule and singlePageModules before they're used in the handlers
const badModule = {
  moduleId: '1086',
  api: '/courses/23/modules/1086/items_html?page=1&per_page=2',
  response: new Response('', {status: 500}),
}

const singlePageModules = {
  moduleId: '1087',
  items: '<ul><li id="21"></li><li id="22"></li></ul>',
  api: '/courses/23/modules/1087/items_html?page=1&per_page=2',
}

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

const handlers = [
  http.get<{courseId: string; moduleId: string}>(
    '/courses/:courseId/modules/:moduleId/items_html',
    ({params, request}) => {
      const {moduleId} = params
      const url = new URL(request.url)
      const page = url.searchParams.get('page') || '1'

      // Handle bad module case
      if (moduleId === badModule.moduleId) {
        return badModule.response
      }

      // Handle single page module case
      if (moduleId === singlePageModules.moduleId) {
        return new HttpResponse(singlePageModules.items, {
          headers: {
            'Content-Type': 'text/html',
          },
        })
      }

      // Handle regular modules
      const moduleData = modules[moduleId]
      if (!moduleData) {
        return new HttpResponse(null, {status: 404})
      }

      // For pagination testing, handle module 2000 specially
      if (moduleId === '2000') {
        if (page === '2') {
          // Simulate an empty page for page 2
          return new HttpResponse('', {
            status: 200,
            headers: {
              'Content-Type': 'text/html',
              Link: `</courses/${courseId}/modules/2000/items_html?page=2&per_page=2>; rel="next"`,
            },
          })
        } else if (page === '1') {
          // Return content for page 1
          return new HttpResponse('<ul><li id="23"></li><li id="24"></li></ul>', {
            status: 200,
            headers: {
              'Content-Type': 'text/html',
              Link: `</courses/${courseId}/modules/2000/items_html?page=1&per_page=2>; rel="current",</courses/${courseId}/modules/2000/items_html?page=2&per_page=2>; rel="next",</courses/${courseId}/modules/2000/items_html?page=1&per_page=2>; rel="first",</courses/${courseId}/modules/2000/items_html?page=2&per_page=2>; rel="last"`,
            },
          })
        }
      }

      // Return the module data with appropriate headers
      return new HttpResponse(moduleData.items, {
        headers: {
          'Content-Type': 'text/html',
          Link: moduleData.link,
        },
      })
    },
  ),
]

const server = setupServer(...handlers)

const createMockModule = (moduleId: string) => {
  const module = document.createElement('div')
  module.id = `context_module_${moduleId}`
  const content = document.createElement('div')
  content.id = `context_module_content_${moduleId}`
  const items = document.createElement('ul')
  items.className = 'context_module_items'
  content.appendChild(items)
  const footer = document.createElement('footer')
  footer.className = 'footer'
  content.appendChild(footer)
  module.appendChild(content)
  document.getElementById('context_modules')?.appendChild(module)
}
// Create mock modules
createMockModule(badModule.moduleId)
createMockModule(singlePageModules.moduleId)

let moduleItemsLazyLoader: ModuleItemsLazyLoader
let itemsCallback: ModuleItemsCallback
const mockStore = new ModuleItemsStore(courseId, accountId, userId)

describe('fetchModuleItems utility', () => {
  beforeEach(() => {
    itemsCallback = jest.fn()
    // Reset the store to ensure page numbers are cleared before each test
    Object.keys(modules).forEach((moduleId: string) => {
      mockStore.removePageNumber(moduleId)
    })
    moduleItemsLazyLoader = new ModuleItemsLazyLoader(courseId, itemsCallback, mockStore, pageSize)

    document.body.innerHTML =
      '<div id="flash_screenreader_holder" role="alert"></div><div id="context_modules"></div>'
    Object.keys(modules).forEach((moduleId: string) => {
      createMockModule(moduleId)
    })
    createMockModule(badModule.moduleId)
  })

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    server.resetHandlers()

    // Clean up React roots before clearing DOM
    // @ts-expect-error - Accessing private static property for testing
    const loadingData = ModuleItemsLazyLoader.loadingData
    Object.keys(modules).forEach((moduleId: string) => {
      try {
        loadingData.unmountModuleRoot(moduleId)
      } catch (_e) {
        // Ignore unmount errors during cleanup
      }
    })
    try {
      loadingData.unmountModuleRoot(badModule.moduleId)
    } catch (_e) {
      // Ignore unmount errors during cleanup
    }
    try {
      loadingData.unmountModuleRoot(singlePageModules.moduleId)
    } catch (_e) {
      // Ignore unmount errors during cleanup
    }

    document.body.innerHTML = ''
    jest.restoreAllMocks()

    // Clear localStorage entries with PREFIX to prevent state leakage between tests
    Object.keys(localStorage).forEach(key => {
      if (key.startsWith(PREFIX)) {
        localStorage.removeItem(key)
      }
    })

    // Reset the static loadingData property
    // @ts-expect-error - Accessing private static property for testing
    ModuleItemsLazyLoader.loadingData = new ModuleItemLoadingData()
  })

  describe('fetchModuleItems', () => {
    it('does nothing if no modules are provided', async () => {
      const serverRequestSpy = jest.spyOn(server, 'use')
      try {
        await moduleItemsLazyLoader.fetchModuleItems([])
        expect(itemsCallback).not.toHaveBeenCalled()
        expect(serverRequestSpy).not.toHaveBeenCalled()
      } finally {
        serverRequestSpy.mockRestore()
      }
    })

    it('does nothing if the provided moduleIds not exist in the dom', async () => {
      const serverRequestSpy = jest.spyOn(server, 'use')
      try {
        await moduleItemsLazyLoader.fetchModuleItems(['noop'])
        expect(itemsCallback).not.toHaveBeenCalled()
        expect(serverRequestSpy).not.toHaveBeenCalled()
      } finally {
        serverRequestSpy.mockRestore()
      }
    })

    it('constructs the api urls correctly', async () => {
      const requestSpy = jest.fn()
      server.events.on('request:match', requestSpy)
      try {
        await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
        const requestUrls = requestSpy.mock.calls.map(call => call[0].request.url)
        Object.keys(modules).forEach(moduleId => {
          expect(
            requestUrls.some(url =>
              url.includes(`/courses/${courseId}/modules/${moduleId}/items_html`),
            ),
          ).toBe(true)
        })
      } finally {
        server.events.removeListener('request:match', requestSpy)
      }
    })

    it('fetches the items with correct query parameters', async () => {
      const requestSpy = jest.fn()
      server.events.on('request:match', requestSpy)
      try {
        await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
        const requestUrls = requestSpy.mock.calls.map(call => call[0].request.url)
        requestUrls.forEach(url => {
          expect(url).toContain(`page=1&per_page=${pageSize}`)
        })
      } finally {
        server.events.removeListener('request:match', requestSpy)
      }
    })

    describe('success responses', () => {
      it('sets the html in the containers with the results', async () => {
        await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
        await waitFor(() => {
          Object.keys(modules).forEach(moduleId => {
            expect(
              document.querySelector(`#context_module_content_${moduleId} ul`)?.outerHTML,
            ).toEqual(modules[moduleId].items)
          })
        })
      })

      it("calls the callback for each module's items", async () => {
        await moduleItemsLazyLoader.fetchModuleItems(Object.keys(modules))
        Object.keys(modules).forEach(moduleId =>
          expect(itemsCallback).toHaveBeenCalledWith(moduleId),
        )
      })

      it("sets the loadstate to 'paginated' when there are multiple pages", async () => {
        await moduleItemsLazyLoader.fetchModuleItems(['1083'])
        await waitFor(() => {
          const module = moduleFromId('1083')
          expect(module?.dataset.loadstate).toBe('paginated')
        })
      })

      it("sets the loadstate to 'loaded' when there is only one page", async () => {
        createMockModule(singlePageModules.moduleId)
        await moduleItemsLazyLoader.fetchModuleItems([singlePageModules.moduleId])
        const module = moduleFromId(singlePageModules.moduleId)
        expect(module?.dataset.loadstate).toBe('loaded')
      })

      it('sets the loadstate to "error" when the fetch fails', async () => {
        await moduleItemsLazyLoader.fetchModuleItems([badModule.moduleId])
        const module = moduleFromId(badModule.moduleId)
        expect(module?.dataset.loadstate).toBe('error')
      })
    })

    describe('failed responses', () => {
      const badModuleId = badModule.moduleId

      it('handles the error appropriately', async () => {
        await moduleItemsLazyLoader.fetchModuleItems([badModuleId])
        expect(itemsCallback).not.toHaveBeenCalled()
        const module = document.getElementById(`context_module_${badModuleId}`)
        expect(module?.getAttribute('data-loadstate')).toBe('error')
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

  describe('fetchModuleItemsHtml', () => {
    const moduleId = '1083'

    it('does nothing if the provided moduleId not exist in the dom', async () => {
      const serverRequestSpy = jest.spyOn(server, 'use')
      await moduleItemsLazyLoader.fetchModuleItemsHtml('noop', 1)
      // Verify no network requests were made
      expect(serverRequestSpy).not.toHaveBeenCalled()
      serverRequestSpy.mockRestore()
    })

    it('fetches the item', async () => {
      await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1)
      await waitFor(() => {
        expect(document.querySelector(`#context_module_content_${moduleId} ul`)).toBeInTheDocument()
      })
    })

    describe('allPages storing', () => {
      describe('get', () => {
        let getShowAllSpy: jest.SpyInstance

        beforeEach(() => {
          getShowAllSpy = jest.spyOn(mockStore, 'getShowAll')
        })

        describe('when allPagesParam is provided', () => {
          const allPagesParam = true

          it('should not call the getPageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, undefined, allPagesParam)
            expect(getShowAllSpy).not.toHaveBeenCalled()
          })
        })

        describe('when allPagesParam is not provided', () => {
          it('should call the getPageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId)
            expect(getShowAllSpy).toHaveBeenCalledWith(moduleId)
          })
        })
      })

      describe('set', () => {
        let setShowAllSpy: jest.SpyInstance
        let removePageNumberSpy: jest.SpyInstance

        beforeEach(() => {
          setShowAllSpy = jest.spyOn(mockStore, 'setShowAll')
          removePageNumberSpy = jest.spyOn(mockStore, 'removePageNumber')
        })

        describe('when allPage is false', () => {
          const allPages = false

          it('should not call removePageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, undefined, allPages)
            expect(removePageNumberSpy).not.toHaveBeenCalled()
          })

          it('should call setShowAll', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, undefined, allPages)
            expect(setShowAllSpy).toHaveBeenCalledWith(moduleId, allPages)
          })
        })

        describe('when allPage is true', () => {
          const allPages = true

          it('should call removePageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, undefined, allPages)
            expect(removePageNumberSpy).toHaveBeenCalledWith(moduleId)
          })

          it('should call setShowAll', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, undefined, allPages)
            expect(setShowAllSpy).toHaveBeenCalledWith(moduleId, allPages)
          })
        })
      })
    })

    describe('pageNumber storing', () => {
      describe('get', () => {
        let getPageNumberSpy: jest.SpyInstance

        beforeEach(() => {
          getPageNumberSpy = jest.spyOn(mockStore, 'getPageNumber')
        })

        describe('when pageParam is provided', () => {
          const pageParam = 2

          it('should not call the getPageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, pageParam)
            expect(getPageNumberSpy).not.toHaveBeenCalled()
          })
        })

        describe('when pageParam is not provided', () => {
          it('should call the getPageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId)
            expect(getPageNumberSpy).toHaveBeenCalledWith(moduleId)
          })
        })
      })

      describe('set', () => {
        let setPageNumberSpy: jest.SpyInstance
        let removePageNumberSpy: jest.SpyInstance

        beforeEach(() => {
          setPageNumberSpy = jest.spyOn(mockStore, 'setPageNumber')
          removePageNumberSpy = jest.spyOn(mockStore, 'removePageNumber')
        })

        describe('when pageParam is provided and allPage is false', () => {
          const pageParam = 2
          const allPages = false

          it('should call the setPageNumber', async () => {
            // MSW will handle the request, we can verify the store was updated

            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, pageParam, allPages)
            expect(setPageNumberSpy).toHaveBeenCalledWith(moduleId, pageParam)
          })
        })

        describe('when pageParam is not provided and allPage is false', () => {
          const pageParam = undefined
          const allPages = false

          it('should call the setPageNumber', async () => {
            jest.spyOn(mockStore, 'getPageNumber').mockImplementation(() => '')
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, pageParam, allPages)
            expect(setPageNumberSpy).toHaveBeenCalledWith(moduleId, 1)
          })
        })

        describe('when allPage is true', () => {
          const pageParam = 2
          const allPages = true

          it('should call removePageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, pageParam, allPages)
            expect(removePageNumberSpy).toHaveBeenCalledWith(moduleId)
          })
        })

        describe('when allPage is false', () => {
          const pageParam = 2
          const allPages = false

          it('should not call removePageNumber', async () => {
            await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, pageParam, allPages)
            expect(removePageNumberSpy).not.toHaveBeenCalled()
          })
        })
      })
    })

    describe('success response', () => {
      it('sets the html in the container with the result', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1)
        expect(document.querySelector(`#context_module_content_${moduleId} ul`)?.outerHTML).toEqual(
          modules[moduleId].items,
        )
      })

      it("calls the callback for the module's item", async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1)
        expect(itemsCallback).toHaveBeenCalledWith(moduleId)
      })
    })

    describe('failed response', () => {
      const badModuleId = badModule.moduleId

      it('does not set the html', async () => {
        const callback = () => {
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
        await moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        expect(
          document.querySelector(`#context_module_${badModuleId} ul.context_module_items`)
            ?.innerHTML,
        ).toBe('')
      })

      it('does not call the callback', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        expect(itemsCallback).not.toHaveBeenCalled()
      })

      it('retries on clicking the retry button', async () => {
        const requestSpy = jest.fn()
        server.events.on('request:match', requestSpy)
        try {
          await moduleItemsLazyLoader.fetchModuleItemsHtml(badModule.moduleId, 1)

          // Wait for the error state to be set and the React component to render
          await waitFor(
            () => {
              const module = moduleFromId(badModule.moduleId)
              expect(module?.dataset.loadstate).toBe('error')
            },
            {timeout: 5000},
          )

          // Give React an additional tick to render the error component
          await waitFor(
            () => {
              expect(screen.getByTestId('items-failed-to-load')).toBeInTheDocument()
            },
            {timeout: 5000},
          )

          await waitFor(
            () => {
              expect(screen.getByTestId('retry-items-failed-to-load')).toBeInTheDocument()
            },
            {timeout: 1000},
          )

          const retryButton = screen.getByTestId('retry-items-failed-to-load').closest('button')
          expect(retryButton).toBeInTheDocument()
          expect(requestSpy).toHaveBeenCalledTimes(1)

          retryButton?.click()
          await waitFor(() => {
            expect(requestSpy).toHaveBeenCalledTimes(2)
          })
        } finally {
          server.events.removeListener('request:match', requestSpy)
        }
      })
    })

    describe('pagination', () => {
      it('renders the Pagination component if there are more than one page', async () => {
        const callback = () => {
          expect(screen.getByTestId('module-1083-pagination')).toBeInTheDocument()
        }
        const moduleItemsLazyLoader = new ModuleItemsLazyLoader(
          courseId,
          callback,
          mockStore,
          pageSize,
        )
        await moduleItemsLazyLoader.fetchModuleItemsHtml('1083', 1)
      })

      it('does not render the Pagination component if there is only one page', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml('1083', 1)
        expect(document.querySelector(`#context_module_content_1083 ul`)?.outerHTML).toEqual(
          modules['1083'].items,
        )
        expect(screen.queryByTestId('module-1083-pagination')).not.toBeInTheDocument()
      })

      it('does not render the Pagination component if allPages is on', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml('1083', 1, true)

        await waitFor(() => {
          expect(screen.queryByTestId('module-1083-pagination')).not.toBeInTheDocument()
        })
      })

      describe('behavior when a page is empty', () => {
        const moduleId = '2000'

        beforeEach(() => {
          createMockModule(moduleId)
        })

        afterEach(() => {
          const container = document.querySelector(`#context_module_content_${moduleId}`)
          if (container) {
            container.innerHTML = ''
          }
        })

        it('should handle empty page response gracefully', async () => {
          await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 1, false)

          const module = document.getElementById(`context_module_${moduleId}`)
          expect(module).not.toBeNull()
          expect(module?.dataset.loadstate).toBeDefined()

          const content = document.querySelector(`#context_module_content_${moduleId}`)
          expect(content).toBeInTheDocument()
        })
      })
    })
  })
})
