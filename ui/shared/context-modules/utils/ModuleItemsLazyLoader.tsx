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
import {FetchError} from '@canvas/context-modules/utils/FetchError'
import {ModuleItemPaging} from '@canvas/context-modules/utils/ModuleItemPaging'
import {ModuleItemLoadingData, type ModuleId} from './ModuleItemLoadingData'

const DEFAULT_PAGE_SIZE = 10
const BATCH_SIZE = 6
const DEFAULT_PAGE = 1

type ModuleItems = string
type ModuleItemsCallback = (moduleId: ModuleId, links?: Links) => void

class ModuleItemsLazyLoader {
  private courseId: string = ''
  private loadingData: ModuleItemLoadingData = new ModuleItemLoadingData()
  private callback: ModuleItemsCallback = () => {}
  private perPage: number = DEFAULT_PAGE_SIZE

  constructor(
    courseId: string,
    callback: ModuleItemsCallback,
    perPage: number = DEFAULT_PAGE_SIZE,
  ) {
    this.courseId = courseId
    this.callback = callback
    this.perPage = perPage
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

    if (links?.current && links?.first && links?.last) {
      const firstPage = parseInt(links.first.page, 10) || DEFAULT_PAGE
      const currentPage = parseInt(links.current.page, 10) || DEFAULT_PAGE
      const lastPage = parseInt(links.last.page, 10) || DEFAULT_PAGE
      if (lastPage > firstPage) {
        const root = this.loadingData.getModuleRoot(moduleId)
        if (!root) return

        root.render(
          <ModuleItemPaging
            isLoading={false}
            paginationOpts={{
              moduleId,
              currentPage,
              totalPages: lastPage,
              onPageChange: (page: number) => this.onPageChange(page, moduleId),
            }}
          />,
        )
      } else {
        this.loadingData.unmountModuleRoot(moduleId)
      }
    } else {
      this.loadingData.unmountModuleRoot(moduleId)
    }
  }

  onPageChange(page: number, moduleId: ModuleId) {
    this.fetchModuleItemsHtml(moduleId, page)
  }

  renderError(moduleId: ModuleId, page: number) {
    const root = this.loadingData.getModuleRoot(moduleId)
    if (!root) return
    root.render(
      <FetchError
        retryCallback={() => {
          this.fetchModuleItemsHtml(moduleId, page)
        }}
      />,
    )
  }

  async fetchModuleItemsHtml(moduleId: ModuleId, page: number = 1): Promise<void> {
    const moduleItemContainer = document.querySelector(`#context_module_content_${moduleId}`)
    if (!moduleItemContainer) return

    try {
      const root = this.loadingData.getModuleRoot(moduleId)
      if (root) {
        root.render(<ModuleItemPaging isLoading={true} />)
      }

      const result = await doFetchApi<ModuleItems>({
        path: `/courses/${this.courseId}/modules/${moduleId}/items_html?page=${page}&per_page=${this.perPage}`,
        headers: {
          accept: 'text/html',
        },
      })

      this.renderResult(moduleId, moduleItemContainer, result.text, result.link)
      this.callback(moduleId)
    } catch (_e) {
      this.renderError(moduleId, page)
    }
  }

  async fetchModuleItems(moduleIds: ModuleId[]): Promise<void> {
    for (let i = 0; i < moduleIds.length; i += BATCH_SIZE) {
      const batch = moduleIds.slice(i, i + BATCH_SIZE)
      await Promise.all(
        batch.map(moduleId => {
          return this.fetchModuleItemsHtml(moduleId, 1)
        }),
      )
    }
  }
}

export {ModuleItemsLazyLoader, type ModuleId, type ModuleItems, type ModuleItemsCallback}
