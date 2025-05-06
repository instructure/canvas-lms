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
import {ModuleItemPaging, type PaginationOpts} from './ModuleItemPaging'
import {ModuleItemLoadingData, type ModuleId} from './ModuleItemLoadingData'
import {ModuleItemsStore} from './ModuleItemsStore'

const DEFAULT_PAGE_SIZE = 10
const BATCH_SIZE = 6
export const DEFAULT_PAGE = 1

type ModuleItems = string
type ModuleItemsCallback = (moduleId: ModuleId, links?: Links) => void

class ModuleItemsLazyLoader {
  private static loadingData = new ModuleItemLoadingData()
  private moduleItemStore: ModuleItemsStore

  private readonly courseId: string = ''
  private readonly callback: ModuleItemsCallback = () => {}
  private readonly perPage: number = DEFAULT_PAGE_SIZE
  private paginationOpts: PaginationOpts = {
    moduleId: '',
    currentPage: 1,
    totalPages: 1,
    onPageChange: () => {},
  }

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
    this.paginationOpts.onPageChange = this.onPageChange.bind(this)
  }

  emptyModuleOfItems(moduleItemContainer: Element) {
    const currentItems = moduleItemContainer.querySelector('.context_module_items')
    if (currentItems) {
      currentItems.remove()
    }
  }

  renderResult(moduleId: ModuleId, moduleItemContainer: Element, text: string, links?: Links) {
    this.emptyModuleOfItems(moduleItemContainer)
    moduleItemContainer.insertAdjacentHTML('afterbegin', text)
    this.paginationOpts.moduleId = moduleId

    if (links?.current && links?.first && links?.last) {
      const firstPage = parseInt(links.first.page, 10) || DEFAULT_PAGE
      this.paginationOpts.currentPage = parseInt(links.current.page, 10) || DEFAULT_PAGE
      this.paginationOpts.totalPages = parseInt(links.last.page, 10) || DEFAULT_PAGE
      if (this.paginationOpts.totalPages > firstPage) {
        const root = ModuleItemsLazyLoader.loadingData.getModuleRoot(moduleId)
        if (!root) return

        root.render(<ModuleItemPaging isLoading={false} paginationOpts={this.paginationOpts} />)
      } else {
        ModuleItemsLazyLoader.loadingData.unmountModuleRoot(moduleId)
      }
    } else {
      ModuleItemsLazyLoader.loadingData.unmountModuleRoot(moduleId)
    }
  }

  onPageChange(page: number, moduleId: ModuleId) {
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
    allPages: boolean = false,
  ): Promise<void> {
    const moduleItemContainer = document.querySelector(`#context_module_content_${moduleId}`)
    if (!moduleItemContainer) return

    const page = this.getPageNumber(moduleId, pageParam)

    try {
      this.paginationOpts.moduleId = moduleId
      this.paginationOpts.currentPage = page
      const root = ModuleItemsLazyLoader.loadingData.getModuleRoot(moduleId)
      if (root) {
        root.render(<ModuleItemPaging isLoading={true} paginationOpts={this.paginationOpts} />)
      }

      const pathParams = allPages ? 'no_pagination=1' : `page=${page}&per_page=${this.perPage}`

      const result = await doFetchApi<ModuleItems>({
        path: `/courses/${this.courseId}/modules/${moduleId}/items_html?${pathParams}`,
        headers: {
          accept: 'text/html',
        },
      })

      this.savePageNumber(moduleId, allPages, page)
      this.renderResult(moduleId, moduleItemContainer, result.text, result.link)
      this.callback(moduleId)
    } catch (_e) {
      this.renderError(moduleId, page)
    }
  }

  private getPageNumber(moduleId: ModuleId, pageParam?: number) {
    return pageParam ? pageParam : Number(this.moduleItemStore.getPageNumber(moduleId)) || 1
  }

  private savePageNumber(moduleId: ModuleId, allPages: boolean, page: number) {
    if (!allPages && page) {
      this.moduleItemStore.setPageNumber(moduleId, page)
    }

    if (allPages) {
      this.moduleItemStore.removePageNumber(moduleId)
    }
  }

  async fetchModuleItems(moduleIds: ModuleId[], allPages: boolean = false): Promise<void[]> {
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
