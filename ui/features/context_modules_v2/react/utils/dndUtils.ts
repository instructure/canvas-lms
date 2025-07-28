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

import {DropResult} from 'react-beautiful-dnd'
import {InfiniteData, QueryClient} from '@tanstack/react-query'
import type {ModulesResponse} from './types'

const getModuleItemsFromDOM = (moduleId: string): any[] => {
  const moduleElement = document.querySelector(`[data-module-id="${moduleId}"]`)
  const itemElements = moduleElement?.querySelectorAll('[data-item-id]') || []

  return Array.from(itemElements)
    .map((el, index) => ({
      id: el.getAttribute('data-item-id'),
      _id: el.getAttribute('data-item-id'),
      content: {title: el.textContent?.trim() || `Item ${index + 1}`},
    }))
    .filter((item, index, self) => index === self.findIndex(t => t._id === item._id))
}

export const uniqueItems = (items: any[]): any[] =>
  items.filter((item, index, self) => index === self.findIndex(t => t._id === item._id))

export const updateIndexes = (items: any[]): any[] =>
  items.map((item: any, idx: number) => ({...item, index: idx}))

export const getItemIds = (items: any[]): string[] =>
  items.map((item: any) => item._id).filter(Boolean)

export const handleMoveItem = (
  dragIndex: number,
  hoverIndex: number,
  dragModuleId: string,
  hoverModuleId: string,
  data: InfiniteData<ModulesResponse> | undefined,
  courseId: string,
  reorderItemsMutation: any,
) => {
  if (!data?.pages) return

  const allModules = data.pages.flatMap(page => page.modules)
  const updatedModules = JSON.parse(JSON.stringify(allModules))

  const dragModule = updatedModules.find((m: {_id: string}) => m._id === dragModuleId)
  const hoverModule = updatedModules.find((m: {_id: string}) => m._id === hoverModuleId)

  if (!dragModule || !hoverModule) return

  if (!dragModule.moduleItems?.length) {
    dragModule.moduleItems = getModuleItemsFromDOM(dragModuleId)
  }
  if (
    (!hoverModule.moduleItems?.length && hoverModuleId !== dragModuleId) ||
    !hoverModule.moduleItems
  ) {
    hoverModule.moduleItems = getModuleItemsFromDOM(hoverModuleId)
  }

  dragModule.moduleItems = uniqueItems(dragModule.moduleItems)
  hoverModule.moduleItems = uniqueItems(hoverModule.moduleItems)

  const [draggedItem] = dragModule.moduleItems.splice(dragIndex, 1)
  if (!draggedItem) return

  if (dragModuleId !== hoverModuleId) {
    hoverModule.moduleItems.splice(hoverIndex, 0, draggedItem)
  } else {
    dragModule.moduleItems.splice(hoverIndex, 0, draggedItem)
  }

  const itemIds = hoverModule.moduleItems.map((item: {_id: string}) => item._id).filter(Boolean)

  if (itemIds.length) {
    reorderItemsMutation.mutate({
      courseId,
      moduleId: hoverModuleId,
      oldModuleId: dragModuleId,
      order: itemIds,
    })
  } else {
    console.error('No valid item IDs to reorder')
  }
}

export const handleDragEnd = (
  result: DropResult,
  data: InfiniteData<ModulesResponse> | undefined,
  courseId: string,
  queryClient: QueryClient,
  reorderModulesMutation: any,
  handleMoveItemFn: (
    sourceIndex: number,
    destinationIndex: number,
    sourceModuleId: string,
    destinationModuleId: string,
  ) => void,
) => {
  if (!result.destination || !data?.pages) {
    return
  }

  const sourceIndex = result.source.index
  const destinationIndex = result.destination.index

  if (result.type === 'MODULE') {
    const allModules = data.pages.flatMap(page => page.modules)

    if (sourceIndex < 0 || sourceIndex >= allModules.length) {
      return
    }

    const newModules = Array.from(allModules)
    const [movedModule] = newModules.splice(sourceIndex, 1)

    if (!movedModule) {
      return
    }

    newModules.splice(destinationIndex, 0, movedModule)

    queryClient.setQueryData(['modules', courseId], (oldData: any) => ({
      ...oldData,
      pages: oldData.pages.map((page: any) => ({
        ...page,
        modules: newModules,
      })),
    }))

    const moduleIds = newModules.filter(m => m && m._id).map(m => m._id)

    if (moduleIds.length > 0) {
      reorderModulesMutation.mutate({
        courseId,
        order: moduleIds,
      })
    }
  } else if (result.type === 'MODULE_ITEM') {
    const sourceModuleId = result.source.droppableId
    const destinationModuleId = result.destination.droppableId

    if (sourceModuleId && destinationModuleId) {
      handleMoveItemFn(sourceIndex, destinationIndex, sourceModuleId, destinationModuleId)
    }
  }
}
