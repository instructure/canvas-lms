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

import {create} from 'zustand'
import {EnvCommon} from '@canvas/global/env/EnvCommon'

declare const ENV: EnvCommon & {
  COURSE_SETTINGS_NAVIGATION_TABS?: NavigationTabFromEnv[]
}

// MoveItemTray requires id strings so use these internally
export type NavigationTab = NavigationTabFromEnv & {
  id: string
}

// Used only to get input from ENV variable
type NavigationTabFromEnv = {
  id: number | string
  label: string
  hidden?: boolean
  disabled_message?: string
  external?: boolean
  css_class?: string
  href?: string
  position?: number
  immovable?: boolean
}

export type MoveItemTrayResult = {
  data: string[]
  itemIds?: string[]
}

export interface TabListsState {
  enabledTabs: NavigationTab[]
  disabledTabs: NavigationTab[]
  moveTab: (result: {
    source: {droppableId: string; index: number}
    destination: {droppableId: string; index: number} | null | undefined
  }) => void
  toggleTabEnabled: (tabId: string) => void
  moveUsingTrayResult: (result: MoveItemTrayResult) => void
}

function reorder<T>(list: T[], sourceIndex: number, destIndex: number): T[] {
  const result = Array.from(list)
  if (list[sourceIndex] !== undefined) {
    const [removed] = result.splice(sourceIndex, 1)
    result.splice(destIndex, 0, removed)
  }
  return result
}

function moveBetweenLists(
  source: NavigationTab[],
  destination: NavigationTab[],
  sourceIndex: number,
  destinationIndex: number,
  merge: Partial<NavigationTab>,
): {newSource: NavigationTab[]; newDestination: NavigationTab[]} {
  const sourceClone = Array.from(source)
  const destClone = Array.from(destination)

  if (destination.every(tab => tab.immovable) && destinationIndex === 0) {
    // Special case: if there are only immovable tabs in a list (currently only
    // enabledTabs in our case), the DnD system will put dragged tabs at the
    // beginning. We should actually the new tab at the end (after Home in our case)
    destinationIndex = destination.length
  }

  if (sourceClone[sourceIndex] !== undefined) {
    const [removed] = sourceClone.splice(sourceIndex, 1)
    destClone.splice(destinationIndex, 0, {...removed, ...merge})
  }

  return {
    newSource: sourceClone,
    newDestination: destClone,
  }
}

export const useTabListsStore = create<TabListsState>((set, get) => {
  const initialTabsInput = ENV.COURSE_SETTINGS_NAVIGATION_TABS || []
  const initialTabs: NavigationTab[] = initialTabsInput.map(tab => ({
    ...tab,
    id: tab.id.toString(),
  }))

  return {
    enabledTabs: initialTabs.filter(tab => !tab.hidden),
    disabledTabs: initialTabs.filter(tab => tab.hidden),

    moveTab: result => {
      if (!result.destination) return

      const {enabledTabs, disabledTabs} = get()
      const {
        source: {droppableId: sourceDroppableId, index: sourceIndex},
        destination: {droppableId: destDroppableId, index: destIndex},
      } = result

      if (sourceDroppableId === destDroppableId) {
        // Reordering within the same list
        if (sourceDroppableId === 'enabled-tabs') {
          set({enabledTabs: reorder(enabledTabs, sourceIndex, destIndex)})
        } else {
          set({disabledTabs: reorder(disabledTabs, sourceIndex, destIndex)})
        }
      } else {
        // Moving between lists (enabled <-> disabled)
        if (sourceDroppableId === 'enabled-tabs') {
          const merge = {hidden: true}
          const moved = moveBetweenLists(enabledTabs, disabledTabs, sourceIndex, destIndex, merge)
          set({enabledTabs: moved.newSource, disabledTabs: moved.newDestination})
        } else {
          const merge = {hidden: false}
          const moved = moveBetweenLists(disabledTabs, enabledTabs, sourceIndex, destIndex, merge)
          set({enabledTabs: moved.newDestination, disabledTabs: moved.newSource})
        }
      }
    },

    toggleTabEnabled: tabId => {
      const {enabledTabs, disabledTabs, moveTab} = get()
      const enabledIndex = enabledTabs.findIndex(tab => tab.id === tabId)
      let source, destination

      if (enabledIndex !== -1) {
        source = {droppableId: 'enabled-tabs', index: enabledIndex}
        destination = {droppableId: 'disabled-tabs', index: disabledTabs.length}
      } else {
        // Tab is currently disabled, enable it
        const disabledIndex = disabledTabs.findIndex(tab => tab.id === tabId)
        if (disabledIndex === -1) return
        source = {droppableId: 'disabled-tabs', index: disabledIndex}
        destination = {droppableId: 'enabled-tabs', index: enabledTabs.length}
      }

      moveTab({source, destination})
    },

    moveUsingTrayResult: moveTrayResult => {
      const {moveTab, enabledTabs, disabledTabs} = get()
      const {data: newOrderedList, itemIds} = moveTrayResult
      // We only support moving 1 item for now
      const tabId = itemIds?.[0]
      if (!tabId) return

      let tabsList, droppableId, sourceIndex
      const indexInEnabled = enabledTabs.findIndex(t => t.id.toString() === tabId.toString())
      if (indexInEnabled > -1) {
        tabsList = enabledTabs
        droppableId = 'enabled-tabs'
        sourceIndex = indexInEnabled
      } else {
        tabsList = disabledTabs
        droppableId = 'disabled-tabs'
        sourceIndex = disabledTabs.findIndex(t => t.id.toString() === tabId.toString())
        if (sourceIndex === -1) return
      }

      // Theoretically we could just set the new list to be the items referenced in newOrderedList,
      // but in case the lists change while the tray is open, it's safer to use
      // moveTab() to move it by index, so we never lose or get extra items

      const destIndexAmongMovable = newOrderedList.findIndex(d => d.toString() === tabId.toString())
      let destIndex
      if (destIndexAmongMovable === -1) {
        console.error('Tab ID not found in move tray result data:', tabId) // shouldn't happen
        return
      } else if (destIndexAmongMovable === 0) {
        // Move to top (after any immovable)
        destIndex = tabsList.findIndex(t => !t.immovable)
      } else {
        const placeAfterId = newOrderedList[destIndexAmongMovable - 1]
        const placeAfterIndex = tabsList.findIndex(t => t.id.toString() === placeAfterId.toString())
        if (placeAfterIndex === -1) {
          // placeAfterId item was moved while tray was open, don't know where to put it, abort
          return
        } else if (placeAfterIndex < sourceIndex) {
          destIndex = placeAfterIndex + 1
        } else {
          destIndex = placeAfterIndex
        }
      }

      moveTab({
        source: {droppableId, index: sourceIndex},
        destination: {droppableId, index: destIndex},
      })
    },
  }
})
