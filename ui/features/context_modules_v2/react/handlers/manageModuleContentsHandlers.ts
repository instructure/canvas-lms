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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Module, ModuleAction, ModuleItem} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

export const createTopOrder = (
  itemToMove: string | string[],
  items: any[],
  itemKey = '_id',
  excludeId = '',
): string[] => {
  const itemsToMove = Array.isArray(itemToMove) ? [...itemToMove] : [itemToMove]
  const order: string[] = [...itemsToMove]

  const addedItems = new Set(itemsToMove)

  if (items) {
    items.forEach(item => {
      const itemId = item[itemKey]
      if (itemId !== excludeId && !addedItems.has(itemId)) {
        order.push(itemId)
        addedItems.add(itemId)
      }
    })
  }
  return order
}

export const createBottomOrder = (
  itemToMove: string | string[],
  items: any[],
  itemKey = '_id',
  excludeId = '',
): string[] => {
  const itemsToMove = Array.isArray(itemToMove) ? [...itemToMove] : [itemToMove]
  const order: string[] = []

  const addedItems = new Set(itemsToMove)

  if (items) {
    items.forEach(item => {
      const itemId = item[itemKey]
      if (itemId !== excludeId && !addedItems.has(itemId)) {
        order.push(itemId)
      }
    })
  }

  order.push(...itemsToMove)
  return order
}

export const createBeforeOrder = (
  itemToMove: string | string[],
  items: any[],
  referenceId: string,
  itemKey = '_id',
  excludeId = '',
): string[] => {
  const itemsToMove = Array.isArray(itemToMove) ? [...itemToMove] : [itemToMove]
  const order: string[] = []
  let foundItem = false

  const addedItems = new Set(itemsToMove)

  if (items) {
    for (const item of items) {
      const itemId = item[itemKey]
      if (itemId === referenceId) {
        foundItem = true
        order.push(...itemsToMove)
        if (!addedItems.has(itemId)) {
          order.push(itemId)
          addedItems.add(itemId)
        }
      } else if (itemId !== excludeId && !addedItems.has(itemId)) {
        order.push(itemId)
        addedItems.add(itemId)
      }
    }
  }

  if (!foundItem) {
    order.push(...itemsToMove)
  }

  return order
}

export const createAfterOrder = (
  itemToMove: string | string[],
  items: any[],
  referenceId: string,
  itemKey = '_id',
  excludeId = '',
): string[] => {
  const itemsToMove = Array.isArray(itemToMove) ? [...itemToMove] : [itemToMove]
  const order: string[] = []
  let foundItem = false

  const addedItems = new Set(itemsToMove)

  if (items) {
    for (const item of items) {
      const itemId = item[itemKey]
      if (itemId === referenceId) {
        foundItem = true
        if (!addedItems.has(itemId)) {
          order.push(itemId)
          addedItems.add(itemId)
        }
        order.push(...itemsToMove)
      } else if (itemId !== excludeId && !addedItems.has(itemId)) {
        order.push(itemId)
        addedItems.add(itemId)
      }
    }
  }

  if (!foundItem) {
    order.push(...itemsToMove)
  }

  return order
}

export const createModuleItemOrder = (
  moduleItemId: string,
  moduleItems: ModuleItem[] | undefined,
  selectedPosition: string,
  selectedItem: string,
): string[] => {
  if (!moduleItems) return []

  if (selectedPosition === 'top') {
    return createTopOrder(moduleItemId, moduleItems, '_id', moduleItemId)
  } else if (selectedPosition === 'bottom') {
    return createBottomOrder(moduleItemId, moduleItems, '_id', moduleItemId)
  } else if (selectedPosition === 'before' && selectedItem) {
    return createBeforeOrder(moduleItemId, moduleItems, selectedItem, '_id', moduleItemId)
  } else if (selectedPosition === 'after' && selectedItem) {
    return createAfterOrder(moduleItemId, moduleItems, selectedItem, '_id', moduleItemId)
  }

  return moduleItems.map(item => item._id)
}

export const createModuleContentsOrder = (
  sourceItems: string[],
  moduleItems: ModuleItem[] | undefined,
  selectedPosition: string,
  selectedItem: string,
): string[] => {
  if (!moduleItems) return []

  if (selectedPosition === 'top') {
    return createTopOrder(sourceItems, moduleItems)
  } else if (selectedPosition === 'bottom') {
    return createBottomOrder(sourceItems, moduleItems)
  } else if (selectedPosition === 'before' && selectedItem) {
    return createBeforeOrder(sourceItems, moduleItems, selectedItem)
  } else if (selectedPosition === 'after' && selectedItem) {
    return createAfterOrder(sourceItems, moduleItems, selectedItem)
  }

  return moduleItems.map(item => item._id)
}

export const createModuleOrder = (
  sourceModuleId: string,
  modules: Module[] | undefined,
  selectedPosition: string,
  selectedItem: string,
): string[] => {
  if (!modules) return []

  if (selectedPosition === 'top') {
    return createTopOrder(sourceModuleId, modules, '_id', sourceModuleId)
  } else if (selectedPosition === 'bottom') {
    return createBottomOrder(sourceModuleId, modules, '_id', sourceModuleId)
  } else if (selectedPosition === 'before' && selectedItem) {
    return createBeforeOrder(sourceModuleId, modules, selectedItem, '_id', sourceModuleId)
  } else if (selectedPosition === 'after' && selectedItem) {
    return createAfterOrder(sourceModuleId, modules, selectedItem, '_id', sourceModuleId)
  }

  return modules.map(module => module._id)
}

export const getTrayTitle = (moduleAction: ModuleAction | null): string => {
  if (moduleAction === 'move_module_contents') {
    return I18n.t('Move Contents Into')
  } else if (moduleAction === 'move_module_item') {
    return I18n.t('Move Item')
  } else if (moduleAction === 'move_module') {
    return I18n.t('Move Module')
  } else {
    return I18n.t('Move')
  }
}

export const getErrorMessage = (moduleAction: ModuleAction | null): string => {
  if (moduleAction === 'move_module_item') {
    return I18n.t('Error moving item')
  } else if (moduleAction === 'move_module_contents') {
    return I18n.t('Error moving module contents')
  } else if (moduleAction === 'move_module') {
    return I18n.t('Error moving module')
  }
  return I18n.t('Error moving')
}
