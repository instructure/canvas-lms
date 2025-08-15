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
import {MODULE_ITEM_TITLES, MODULE_ITEMS, MODULE_ITEMS_QUERY_MAP, MODULES} from '../utils/constants'
import {
  GraphQLResult,
  ModuleActionEventDetail,
  ModuleItem,
  ModulesResponse,
  PaginatedNavigationResponse,
} from '../utils/types'
import {queryClient} from '@canvas/query'
import {handleOpeningModuleUpdateTray} from './modulePageActionHandlers'
import {handleDelete} from './moduleActionHandlers'
import {InfiniteData} from '@tanstack/react-query'
import {updateIndent} from './moduleItemActionHandlers'

const I18n = createI18nScope('context_modules_v2')

const getModuleItemTitles = async ({queryKey}: {queryKey: any}): Promise<Partial<ModuleItem>[]> => {
  const [_key, moduleId] = queryKey
  const persistedQuery = MODULE_ITEMS_QUERY_MAP[MODULE_ITEM_TITLES]
  const itemsQuery = gql`${persistedQuery}`
  try {
    const result = await executeQuery<GraphQLResult>(itemsQuery, {
      moduleId,
    })
    if (result.errors) {
      throw new Error(result.errors.map((err: {message: string}) => err.message).join(', '))
    }
    //@ts-expect-error
    return result.legacyNode?.moduleItemsConnection?.edges.map((edge: any) => edge.node) || []
  } catch (error: any) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load module items: %{error}', {error: errorMessage}))
    throw error
  }
}

class ModulePageCommandEventHandlers {
  // ------ edit ------
  handleEditModule = async (courseId: string, moduleId: string) => {
    if (!(courseId && moduleId)) return

    const moduleData = queryClient.getQueryData([MODULES, courseId]) as
      | InfiniteData<ModulesResponse, unknown>
      | undefined

    const modules = moduleData?.pages[0]?.modules
    if (!modules) return

    const module = modules.find(module => module._id === moduleId)

    if (!module) return

    const itemData = await queryClient.ensureQueryData({
      queryKey: [MODULE_ITEM_TITLES, moduleId],
      queryFn: getModuleItemTitles,
    })

    handleOpeningModuleUpdateTray(
      moduleData,
      courseId,
      moduleId,
      module.name,
      'settings',
      itemData || [],
    )
  }

  // ------ delete ------
  handleDeleteModule = async (courseId: string, moduleId: string) => {
    const module = document.querySelector(`[data-module-id="${moduleId}"]`) as HTMLElement
    if (!module) return
    const moduleName = module?.getAttribute('data-module-name') || `module ${moduleId}`
    handleDelete(moduleId, moduleName, queryClient, courseId)
  }

  // ------ new module ------

  handleNewModule = async () => {
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
    const queryData = queryClient.getQueryData<PaginatedNavigationResponse>([
      MODULE_ITEMS,
      moduleId,
      null,
    ])
    if (!queryData) return
    const moduleItem = queryData.moduleItems.find((item: any) => item._id === moduleItemId)
    return moduleItem
  }

  handleEditModuleItem = async (courseId: string, moduleItemId: string) => {
    console.log('>>>edit item', courseId, moduleItemId)
  }

  handleDeleteModuleItem = async (courseId: string, moduleItemId: string) => {
    console.log('>>>delete item', courseId, moduleItemId)
  }

  handleIndentModuleItem = (courseId: string, moduleId: string, moduleItemId: string) => {
    const moduleItem = this.getModuleItemFromCache(moduleId, moduleItemId)
    if (!moduleItem) return
    const indent = moduleItem.indent
    if (indent < 5) {
      const newIndent = indent + 1
      updateIndent(moduleItemId, moduleId, newIndent, courseId, queryClient)
    }
  }

  handleOutdentModuleItem = (courseId: string, moduleId: string, moduleItemId: string) => {
    const moduleItem = this.getModuleItemFromCache(moduleId, moduleItemId)
    if (!moduleItem) return
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
        if (moduleId) {
          this.handleEditModule(courseId, moduleId)
        } else if (moduleItemId) {
          this.handleEditModuleItem(courseId, moduleItemId)
        }
        break
      case 'delete':
        if (moduleId) {
          this.handleDeleteModule(courseId, moduleId)
        } else if (moduleItemId) {
          this.handleDeleteModuleItem(courseId, moduleItemId)
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
