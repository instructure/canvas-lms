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
import {ModuleItemsLazyLoader, type ModuleItemsCallback} from '../ModuleItemsLazyLoader'
import {ModuleItemsStore} from '../ModuleItemsStore'
import {moduleFromId} from '../showAllOrLess'
import {type ModuleId} from '../types'

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

const createMockModule = (moduleId: string) => {
  const module = document.createElement('div')
  module.id = `context_module_${moduleId}`
  const content = document.createElement('div')
  content.id = `context_module_content_${moduleId}`
  const footer = document.createElement('footer')
  footer.className = 'footer'
  content.appendChild(footer)
  module.appendChild(content)
  document.body.appendChild(module)
}
const badModule = {
  moduleId: '1086',
  api: '/courses/23/modules/1086/items_html?page=1&per_page=2',
  response: new Response('', {status: 500}),
}
fetchMock.mock(badModule.api, badModule.response)
createMockModule(badModule.moduleId)

const singlePageModules = {
  moduleId: '1087',
  items: '<ul><li id="21"></li><li id="22"></li></ul>',
  api: '/courses/23/modules/1087/items_html?page=1&per_page=2',
}
fetchMock.mock(singlePageModules.api, {
  body: singlePageModules.items,
})

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

    document.body.innerHTML = ''
    Object.keys(modules).forEach((moduleId: string) => {
      createMockModule(moduleId)
    })
    createMockModule(badModule.moduleId)
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

    it.skip('construct the api urls correctly', async () => {
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
      it.skip('set the html in the containers with the results', async () => {
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

      it.skip("sets the loadstate to 'paginated' when there are multiple pages", async () => {
        await moduleItemsLazyLoader.fetchModuleItems(['1083'])
        const module = moduleFromId('1083')
        expect(module?.dataset.loadstate).toBe('paginated')
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

  describe('fetchModuleItemsHtml', () => {
    const moduleId = '1083'

    it('does nothing if the provided moduleId not exist in the dom', async () => {
      await moduleItemsLazyLoader.fetchModuleItemsHtml('noop', 1)
      expect(fetchMock.calls()).toHaveLength(0)
    })

    it.skip('construct the api url correctly', async () => {
      // use page=2 here
      fetchMock.mock(
        `/courses/${courseId}/modules/${moduleId}/items_html?page=2&per_page=${pageSize}`,
        200,
        {overwriteRoutes: true},
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
            // Mock the fetch API to avoid actual network calls
            fetchMock.mock(
              `/courses/${courseId}/modules/${moduleId}/items_html?page=${pageParam}&per_page=${pageSize}`,
              {
                body: modules[moduleId].items,
                headers: {
                  link: modules[moduleId].link,
                },
              },
              {overwriteRoutes: true},
            )

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
      it.skip('set the htmls in the container with the result', async () => {
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
      })

      it('does not call the callback', async () => {
        await moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        expect(itemsCallback).not.toHaveBeenCalled()
      })

      // eslint-disable-next-line jest/no-disabled-tests
      it.skip('retries on clicking the retry button', async () => {
        // I cannot understand why the next test starts running before the
        // await waitFor() is satisfied.
        moduleItemsLazyLoader.fetchModuleItemsHtml(badModuleId, 1)
        await waitFor(
          () => {
            expect(screen.getByTestId('retry-items-failed-to-load')).toBeInTheDocument()
          },
          {timeout: 30000},
        )
        expect(fetchMock.calls()).toHaveLength(1)
        const retryButton = screen.getByTestId('retry-items-failed-to-load').closest('button')
        retryButton?.click()
        expect(fetchMock.calls()).toHaveLength(2)
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

      it.skip('does not render the Pagination component if there is only one page', async () => {
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

      describe('behavior when a page get empty', () => {
        const pageParam = 2
        const moduleId = '2000'
        fetchMock.mock(
          `/courses/${courseId}/modules/${moduleId}/items_html?page=${pageParam}&per_page=${pageSize}`,
          {
            headers: {
              // Missing rel="last" to simulate the problematic state
              Link: '</api/v1/accounts/1/account_calendars?page=2&per_page=100>; rel="next"',
            },
          },
        )
        fetchMock.mock(
          `/courses/${courseId}/modules/${moduleId}/items_html?page=${pageParam - 1}&per_page=${pageSize}`,
          {
            headers: {
              Link: '</courses/23/modules/1085/items_html?page=1&per_page=2>; rel="current",</courses/23/modules/1085/items_html?page=2&per_page=2>; rel="next",</courses/23/modules/1085/items_html?page=1&per_page=2>; rel="first",</courses/23/modules/1085/items_html?page=2&per_page=2>; rel="last"',
            },
          },
        )

        beforeEach(() => {
          createMockModule(moduleId)
        })

        afterEach(() => {
          const container = document.querySelector(`#context_module_content_${moduleId}`)
          if (container) {
            container.innerHTML = ''
          }
        })

        it('should render pagination with latest state', async () => {
          await moduleItemsLazyLoader.fetchModuleItemsHtml(moduleId, 2, false)

          await waitFor(() => {
            expect(screen.queryByTestId(`module-${moduleId}-pagination`)).toBeInTheDocument()
          })
        })
      })
    })
  })
})
