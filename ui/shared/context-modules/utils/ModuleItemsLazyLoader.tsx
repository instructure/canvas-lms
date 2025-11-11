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

import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {type Links} from '@canvas/parse-link-header'
import {FetchError} from './FetchError'
import {ModuleItemPaging, type PaginationData} from './ModuleItemPaging'
import {ModuleItemLoadingData} from './ModuleItemLoadingData'
import {ModuleItemsLoadingSpinner} from './ModuleItemsLoadingSpinner'
import {ModuleItemsStore} from './ModuleItemsStore'
import {moduleFromId} from './showAllOrLess'
import {getModuleAriaLabel, updateModuleFileDrop} from './moduleHelpers'
import {DEFAULT_PAGE_SIZE, type ModuleId} from './types'

const BATCH_SIZE = 6

type ModuleItems = string
type ModuleItemsCallback = (moduleId: ModuleId, links?: Links) => void
type BulkModuleItemsResponse = {
  html: string
  pagination: {
    current_page: number
    total_pages: number
    per_page: number
  } | null
}

class ModuleItemsLazyLoader {
  private static loadingData = new ModuleItemLoadingData()
  private moduleItemStore: ModuleItemsStore

  private readonly courseId: string = ''
  private readonly callback: ModuleItemsCallback = () => {}
  private readonly perPage: number = DEFAULT_PAGE_SIZE

  constructor(
    courseId: string,
    callback: ModuleItemsCallback,
    moduleItemStore: ModuleItemsStore,
    perPage: number = DEFAULT_PAGE_SIZE,
  ) {
    this.courseId = courseId
    this.callback = callback
    this.perPage = perPage
    this.moduleItemStore = moduleItemStore
  }

  emptyModuleOfItems(moduleItemContainer: Element, leaveList?: boolean) {
    if (leaveList) {
      moduleItemContainer.querySelector('.context_module_items')?.replaceChildren()
    } else {
      moduleItemContainer.querySelector('.context_module_items')?.remove()
    }
  }

  renderResult(moduleId: ModuleId, text: string, links?: Links) {
    const moduleItemContainer = document.querySelector(`#context_module_content_${moduleId}`)
    if (!moduleItemContainer) return

    this.emptyModuleOfItems(moduleItemContainer, text.trim().length === 0)
    moduleItemContainer.insertAdjacentHTML('afterbegin', text)

    const module = moduleFromId(moduleId)
    if (!module) return
    module.dataset.loadstate = 'loaded'

    const paginationData: PaginationData = ModuleItemsLazyLoader.loadingData.getPaginationData(
      moduleId,
    ) || {currentPage: 1, totalPages: 1}

    if (links?.current && links?.first && links?.last) {
      const page = parseInt(links.current.page, 10)
      if (page) paginationData.currentPage = page
      const totalPages = parseInt(links.last.page, 10)
      if (totalPages) paginationData.totalPages = totalPages
      ModuleItemsLazyLoader.loadingData.setPaginationData(moduleId, paginationData)

      if (paginationData.totalPages > 1) {
        const root = ModuleItemsLazyLoader.loadingData.getModuleRoot(moduleId)
        if (!root) return

        module.dataset.loadstate = 'paginated'

        root.render(
          <ModuleItemPaging
            moduleId={moduleId}
            isLoading={false}
            paginationData={paginationData}
            onPageChange={this.onPageChange}
            moduleName={this.getModuleName(module)}
          />,
        )
      } else {
        ModuleItemsLazyLoader.loadingData.unmountModuleRoot(moduleId)
      }
    } else {
      ModuleItemsLazyLoader.loadingData.unmountModuleRoot(moduleId)
    }
    updateModuleFileDrop(module)
  }

  onPageChange = (page: number, moduleId: ModuleId) => {
    this.fetchModuleItemsHtml(moduleId, page)
  }

  renderError(moduleId: ModuleId, page: number) {
    const root = ModuleItemsLazyLoader.loadingData.getModuleRoot(moduleId)
    if (!root) return
    root.render(
      <FetchError
        retryCallback={() => {
          this.fetchModuleItemsHtml(moduleId, page)
        }}
      />,
    )
  }

  async fetchModuleItemsHtml(
    moduleId: ModuleId,
    pageParam?: number,
    allPagesParam?: boolean,
  ): Promise<DoFetchApiResults<string> | undefined> {
    const module = moduleFromId(moduleId)
    if (!module) return

    const page = this.getPageNumber(moduleId, pageParam)
    const allPages = this.getAllPages(moduleId, allPagesParam)

    try {
      module.dataset.loadstate = 'loading'

      const root = ModuleItemsLazyLoader.loadingData.getModuleRoot(moduleId)
      if (!allPages) {
        const paginationData = ModuleItemsLazyLoader.loadingData.getPaginationData(moduleId)
        root?.render(
          <ModuleItemPaging
            moduleId={moduleId}
            isLoading={true}
            paginationData={paginationData}
            onPageChange={this.onPageChange}
            moduleName={this.getModuleName(module)}
          />,
        )
      } else {
        ModuleItemsLazyLoader.loadingData.removePaginationData(moduleId)
        root?.render(<ModuleItemsLoadingSpinner isLoading={true} />)
      }

      const pathParams = allPages ? 'no_pagination=1' : `page=${page}&per_page=${this.perPage}`

      const result = await doFetchApi<ModuleItems>({
        path: `/courses/${this.courseId}/modules/${moduleId}/items_html?${pathParams}`,
        headers: {
          accept: 'text/html',
        },
      })

      if (!allPages) {
        // check whether the selected page no longer exists, and return the last page if so
        const lastPageNumber = parseInt(result.link?.last?.page || '')
        if (page > lastPageNumber) {
          return this.fetchModuleItemsHtml(moduleId, lastPageNumber)
        }
      }

      this.clearPageNumberIfAllPages(moduleId, allPages)
      this.savePageNumber(moduleId, allPages, page)
      this.saveAllPage(moduleId, allPages)
      this.renderResult(moduleId, result.text, result.link)
      await this.callback(moduleId)
      return result
    } catch (e) {
      module.dataset.loadstate = 'error'
      this.renderError(moduleId, page)
      return undefined
    }
  }

  private getAllPages(moduleId: ModuleId, allPagesParam?: boolean) {
    return allPagesParam !== undefined ? allPagesParam : this.moduleItemStore.getShowAll(moduleId)
  }

  private getPageNumber(moduleId: ModuleId, pageParam?: number) {
    return pageParam ? pageParam : Number(this.moduleItemStore.getPageNumber(moduleId)) || 1
  }

  private savePageNumber(moduleId: ModuleId, allPages: boolean, page: number) {
    if (!allPages && page) {
      this.moduleItemStore.setPageNumber(moduleId, page)
    }
  }

  private saveAllPage(moduleId: ModuleId, allPages: boolean) {
    this.moduleItemStore.setShowAll(moduleId, allPages)
  }

  private clearPageNumberIfAllPages(moduleId: ModuleId, allPages: boolean) {
    if (allPages) {
      this.moduleItemStore.removePageNumber(moduleId)
    }
  }

  async fetchModuleItems(moduleIds: ModuleId[], allPages?: boolean) {
    if (moduleIds.length === 0) return

    const validModuleIds = moduleIds.filter(moduleId => moduleFromId(moduleId))
    if (validModuleIds.length === 0) return

    // For single module, use the individual endpoint to preserve full functionality
    if (validModuleIds.length === 1) {
      return await this.fetchModuleItemsHtml(validModuleIds[0], undefined, allPages).catch(
        error => {
          console.error('Error fetching module items for single module:', error)
        },
      )
    }

    // For multiple modules, use bulk endpoint
    // Backend limits to 40 modules per request - batch if needed
    const MAX_BATCH_SIZE = 40
    for (let i = 0; i < validModuleIds.length; i += MAX_BATCH_SIZE) {
      const batch = validModuleIds.slice(i, i + MAX_BATCH_SIZE)
      await this.fetchModuleItemsBatch(batch, allPages)
    }
  }

  private async fetchModuleItemsBatch(moduleIds: ModuleId[], allPages?: boolean) {
    // Set loading state for all modules before fetching
    moduleIds.forEach(moduleId => {
      const module = moduleFromId(moduleId)
      if (!module) return

      module.dataset.loadstate = 'loading'

      const root = ModuleItemsLazyLoader.loadingData.getModuleRoot(moduleId)
      if (!allPages) {
        const paginationData = ModuleItemsLazyLoader.loadingData.getPaginationData(moduleId)
        root?.render(
          <ModuleItemPaging
            moduleId={moduleId}
            isLoading={true}
            paginationData={paginationData}
            onPageChange={this.onPageChange}
            moduleName={this.getModuleName(module)}
          />,
        )
      } else {
        ModuleItemsLazyLoader.loadingData.removePaginationData(moduleId)
        root?.render(<ModuleItemsLoadingSpinner isLoading={true} />)
      }
    })

    try {
      const pathParams = allPages ? 'no_pagination=1' : `per_page=${this.perPage}`
      const moduleIdsParams = moduleIds.map(id => `module_ids[]=${id}`).join('&')

      const result = await doFetchApi<Record<ModuleId, BulkModuleItemsResponse>>({
        path: `/courses/${this.courseId}/modules/bulk_items_html?${pathParams}&${moduleIdsParams}`,
        headers: {
          accept: 'application/json',
        },
      })

      if (result.json) {
        for (const moduleId of moduleIds) {
          const moduleData = result.json[moduleId]
          if (moduleData) {
            const html = moduleData.html
            const pagination = moduleData.pagination

            this.clearPageNumberIfAllPages(moduleId, allPages || false)
            this.savePageNumber(moduleId, allPages || false, 1)
            this.saveAllPage(moduleId, allPages || false)

            // Convert pagination data to link format if provided
            let links: Links | undefined
            if (pagination && pagination.total_pages > 1) {
              links = {
                current: {
                  page: pagination.current_page.toString(),
                  url: '',
                  rel: 'current',
                },
                first: {
                  page: '1',
                  url: '',
                  rel: 'first',
                },
                last: {
                  page: pagination.total_pages.toString(),
                  url: '',
                  rel: 'last',
                },
              }
            }

            this.renderResult(moduleId, html, links)
            await this.callback(moduleId)
          } else {
            // Module wasn't in the response - handle as individual failure
            const module = moduleFromId(moduleId)
            if (module) {
              module.dataset.loadstate = 'error'
              this.renderError(moduleId, 1)
            }
          }
        }
      }
    } catch (error) {
      console.error('Error fetching bulk module items:', error)
      // Set error state for all modules when the entire request fails
      moduleIds.forEach(moduleId => {
        const module = moduleFromId(moduleId)
        if (module) {
          module.dataset.loadstate = 'error'
          this.renderError(moduleId, 1)
        }
      })
    }
  }

  private getModuleName(module: HTMLElement) {
    return getModuleAriaLabel(module) || ''
  }
}

export {
  ModuleItemsLazyLoader,
  DEFAULT_PAGE_SIZE,
  type ModuleId,
  type ModuleItems,
  type ModuleItemsCallback,
}
