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

import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  MODULE_ITEM_TITLES,
  MODULE_ITEMS,
  MODULE_ITEMS_ALL,
  MODULE_ITEMS_QUERY_MAP,
  MODULES,
  PAGE_SIZE,
  SHOW_ALL_PAGE_SIZE,
  TEACHER,
} from '../utils/constants'
import {
  ModuleActionEventDetail,
  ModuleItem,
  ModulesResponse,
  PaginatedNavigationResponse,
} from '../utils/types'

interface ModuleItemTitlesGraphQLResult {
  legacyNode?: {
    moduleItemsConnection?: {
      edges: Array<{node: Partial<ModuleItem>}>
    }
  }
  errors?: Array<{message: string}>
}
import {queryClient} from '@canvas/query'
import {handleOpeningModuleUpdateTray, handleOpeningEditItemModal} from './modulePageActionHandlers'
import {handleDelete} from './moduleActionHandlers'
import {InfiniteData} from '@tanstack/react-query'
import {updateIndent, handleRemove} from './moduleItemActionHandlers'

const I18n = createI18nScope('context_modules_v2')

const getModuleItemTitles = async ({queryKey}: {queryKey: any}): Promise<Partial<ModuleItem>[]> => {
  const [_key, moduleId] = queryKey
  const persistedQuery = MODULE_ITEMS_QUERY_MAP[MODULE_ITEM_TITLES]
  const itemsQuery = gql`${persistedQuery}`
  try {
    const result = await executeQuery<ModuleItemTitlesGraphQLResult>(itemsQuery, {
      moduleId,
    })
    if (result.errors) {
      throw new Error(result.errors.map((err: {message: string}) => err.message).join(', '))
    }
    return result.legacyNode?.moduleItemsConnection?.edges.map(edge => edge.node) || []
  } catch (error: any) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load module items: %{error}', {error: errorMessage}))
    throw error
  }
}

class ModulePageCommandEventHandlers {
  // --------------- Modules ---------------

  handleEditModule = async (courseId: string, moduleId: string) => {
    if (!(courseId && moduleId)) return

    const moduleData = queryClient.getQueryData([MODULES, courseId]) as
      | InfiniteData<ModulesResponse, unknown>
      | undefined

    const modules = moduleData?.pages[0]?.modules
    if (!modules) return

    const module = modules.find(module => module._id === moduleId)

    if (!module) return

    // In "show all" mode, prioritize the complete data over paginated data
    const allModuleData = queryClient.getQueryData([
      MODULE_ITEMS_ALL,
      moduleId || '',
      TEACHER,
      SHOW_ALL_PAGE_SIZE,
    ]) as {
      moduleItems: ModuleItem[]
    }

    let itemData = allModuleData?.moduleItems

    // Fallback to paginated cache if show all not available
    if (!allModuleData) {
      itemData = await queryClient.ensureQueryData({
        queryKey: [MODULE_ITEM_TITLES, moduleId],
        queryFn: getModuleItemTitles,
      })
    }

    handleOpeningModuleUpdateTray(
      moduleData,
      courseId,
      moduleId,
      module.name,
      'settings',
      itemData || [],
    )
  }

  handleDeleteModule = (courseId: string, moduleId: string) => {
    const module = document.querySelector(`[data-module-id="${moduleId}"]`) as HTMLElement
    if (!module) return
    const moduleName = module?.getAttribute('data-module-name') || `module ${moduleId}`
    handleDelete(moduleId, moduleName, queryClient, courseId)
  }

  handleNewModule = () => {
    // I'm not crazy about clicking the button to get the job done,
    // but it's off in another component tree altogether and this
    // is the cleanest way to get it done
    const addModuleButton = document.querySelector(
      '#context-modules-header-add-module-button',
    ) as HTMLElement | null
    addModuleButton?.click()
  }

  // --------------- ModuleItems ---------------

  getModuleItemFromCache = (moduleId: string, moduleItemId: string) => {
    const queries = queryClient.getQueriesData<PaginatedNavigationResponse>({
      queryKey: [MODULE_ITEMS, moduleId],
      exact: false,
    })

    for (const [queryKey, queryData] of queries) {
      if (queryData) {
        const moduleItem = queryData.moduleItems.find((item: any) => item._id === moduleItemId)
        if (moduleItem) {
          return {moduleItem, queryKey}
        }
      }
    }

    return undefined
  }

  handleEditModuleItem = (courseId: string, moduleId: string, moduleItemId: string) => {
    handleOpeningEditItemModal(courseId, moduleId, moduleItemId)
  }

  handleRemoveModuleItem = (
    courseId: string,
    moduleId: string,
    moduleItemId: string,
    setIsMenuOpen?: (isOpen: boolean) => void,
    onAfterSuccess?: () => void,
  ) => {
    const result = this.getModuleItemFromCache(moduleId, moduleItemId)
    if (!result) return

    const {moduleItem, queryKey} = result
    const cursor = queryKey[2] as string | null
    const currentPageData = queryClient.getQueryData<PaginatedNavigationResponse>(queryKey)
    const isLastItemOnPage = currentPageData?.moduleItems.length === 1
    const isNotFirstPage = cursor !== null

    let currentPageNumber = 1
    if (cursor) {
      try {
        const offset = parseInt(atob(cursor), 10)
        currentPageNumber = Math.floor(offset / PAGE_SIZE) + 1
      } catch {
        currentPageNumber = 1
      }
    }

    const enhancedOnAfterSuccess = () => {
      if (isLastItemOnPage && isNotFirstPage && currentPageNumber > 1) {
        const newPageNumber = currentPageNumber - 1
        document.dispatchEvent(
          new CustomEvent('module-page-navigation', {
            detail: {
              moduleId,
              pageNumber: newPageNumber,
            },
          }),
        )
      }

      if (onAfterSuccess) {
        onAfterSuccess()
      }
    }

    handleRemove(
      moduleId,
      moduleItem._id,
      moduleItem.title,
      queryClient,
      courseId,
      setIsMenuOpen,
      enhancedOnAfterSuccess,
    )
  }

  handleIndentModuleItem = (courseId: string, moduleId: string, moduleItemId: string) => {
    const result = this.getModuleItemFromCache(moduleId, moduleItemId)
    if (!result) return
    const {moduleItem} = result
    const indent = moduleItem.indent
    if (indent < 5) {
      const newIndent = indent + 1
      updateIndent(moduleItemId, moduleId, newIndent, courseId, queryClient)
    }
  }

  handleOutdentModuleItem = (courseId: string, moduleId: string, moduleItemId: string) => {
    const result = this.getModuleItemFromCache(moduleId, moduleItemId)
    if (!result) return
    const {moduleItem} = result
    const indent = moduleItem.indent
    if (indent > 0) {
      const newIndent = indent - 1
      updateIndent(moduleItemId, moduleId, newIndent, courseId, queryClient)
    }
  }

  handleModuleAction = (event: CustomEvent<ModuleActionEventDetail>) => {
    const {action, courseId, moduleId, moduleItemId} = event.detail

    switch (action) {
      case 'edit':
        if (moduleId && moduleItemId) {
          this.handleEditModuleItem(courseId, moduleId, moduleItemId)
        } else if (moduleId) {
          this.handleEditModule(courseId, moduleId)
        }
        break
      case 'delete':
        if (moduleId) {
          this.handleDeleteModule(courseId, moduleId)
        }
        break
      case 'remove':
        if (moduleId && moduleItemId) {
          const setIsMenuOpen = event.detail.setIsMenuOpen as (isOpen: boolean) => void
          const onAfterSuccess = event.detail.onAfterSuccess as () => void
          this.handleRemoveModuleItem(
            courseId,
            moduleId,
            moduleItemId,
            setIsMenuOpen,
            onAfterSuccess,
          )
        }
        break
      case 'new':
        this.handleNewModule()
        break
      case 'indent':
        if (moduleId && moduleItemId) {
          this.handleIndentModuleItem(courseId, moduleId, moduleItemId)
        }
        break
      case 'outdent':
        if (moduleId && moduleItemId) {
          this.handleOutdentModuleItem(courseId, moduleId, moduleItemId)
        }
        break
      default:
        break
    }
  }
}

// the singleton
const modulePageCommandEventHandlers = new ModulePageCommandEventHandlers()

document.addEventListener('module-action', modulePageCommandEventHandlers.handleModuleAction)

export {modulePageCommandEventHandlers}
export default modulePageCommandEventHandlers
