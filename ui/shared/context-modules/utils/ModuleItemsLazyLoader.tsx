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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {type Links} from '@canvas/parse-link-header'
import {FetchError} from './FetchError'
import {ModuleItemPaging, type PaginationData} from './ModuleItemPaging'
import {ModuleItemLoadingData} from './ModuleItemLoadingData'
import {ModuleItemsLoadingSpinner} from './ModuleItemsLoadingSpinner'
import {ModuleItemsStore} from './ModuleItemsStore'
import {moduleFromId} from './showAllOrLess'
import {updateModuleFileDrop} from './moduleHelpers'
import {DEFAULT_PAGE_SIZE, type ModuleId} from './types'

const BATCH_SIZE = 6

type ModuleItems = string
type ModuleItemsCallback = (moduleId: ModuleId, links?: Links) => void

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
  ): Promise<void> {
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

      if (!allPages && !result.link?.last && page > 1) {
        return await this.fetchModuleItemsHtml(moduleId, page - 1)
      }

      this.clearPageNumberIfAllPages(moduleId, allPages)
      this.savePageNumber(moduleId, allPages, page)
      this.saveAllPage(moduleId, allPages)
      this.renderResult(moduleId, result.text, result.link)
      this.callback(moduleId)
    } catch (_e) {
      module.dataset.loadstate = 'error'
      this.renderError(moduleId, page)
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

  async fetchModuleItems(moduleIds: ModuleId[], allPages?: boolean): Promise<void[]> {
    const allPromises: Promise<void>[] = []
    for (let i = 0; i < moduleIds.length; i += BATCH_SIZE) {
      const batch = moduleIds.slice(i, i + BATCH_SIZE)
      await Promise.all(
        batch.map(moduleId => {
          const p = this.fetchModuleItemsHtml(moduleId, undefined, allPages)
          allPromises.push(p)
          return p
        }),
      )
    }
    return Promise.all(allPromises)
  }
}

export {
  ModuleItemsLazyLoader,
  DEFAULT_PAGE_SIZE,
  type ModuleId,
  type ModuleItems,
  type ModuleItemsCallback,
}
