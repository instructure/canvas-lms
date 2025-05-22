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

import React, {useState, useEffect, useCallback, memo} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import ModulePageActionHeader from './ModulePageActionHeader'
import Module from './Module'
import {DragDropContext, Droppable, Draggable, DropResult} from 'react-beautiful-dnd'
import {
  handleCollapseAll,
  handleExpandAll,
  handleToggleExpand,
} from '../handlers/modulePageActionHandlers'
import ManageModuleContentTray from './ManageModuleContent/ManageModuleContentTray'
import {useModules} from '../hooks/queries/useModules'
import {useReorderModuleItems} from '../hooks/mutations/useReorderModuleItems'
import {useReorderModules} from '../hooks/mutations/useReorderModules'
import {useContextModule} from '../hooks/useModuleContext'
import {queryClient} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleAction} from '../utils/types'
import {updateIndexes, getItemIds, handleDragEnd as dndHandleDragEnd} from '../utils/dndUtils'

const I18n = createI18nScope('context_modules_v2')

const MemoizedModule = memo(Module, (prevProps, nextProps) => {
  return (
    prevProps.id === nextProps.id &&
    prevProps.expanded === nextProps.expanded &&
    prevProps.published === nextProps.published &&
    prevProps.name === nextProps.name &&
    prevProps.hasActiveOverrides === nextProps.hasActiveOverrides
  )
})

const ModulesList: React.FC = () => {
  const {courseId} = useContextModule()
  const reorderItemsMutation = useReorderModuleItems()
  const reorderModulesMutation = useReorderModules()
  const {data, isLoading, error} = useModules(courseId || '')

  // Initialize with an empty Map - all modules will be collapsed by default
  const [expandedModules, setExpandedModules] = useState<Map<string, boolean>>(new Map())

  // State for managing the module content tray
  const [isManageModuleContentTrayOpen, setIsManageModuleContentTrayOpen] = useState(false)
  const [moduleAction, setModuleAction] = useState<ModuleAction | null>(null)
  const [selectedModuleItem, setSelectedModuleItem] = useState<{id: string; title: string} | null>(
    null,
  )
  const [sourceModule, setSourceModule] = useState<{id: string; title: string} | null>(null)

  // Set initial expanded state for modules when data is loaded
  useEffect(() => {
    if (data) {
      const allModules = data.pages?.flatMap(page => page.modules) || []

      // Create a Map with all modules collapsed by default
      const initialExpandedState = new Map<string, boolean>()
      allModules.forEach((module, index) => {
        // Expand the first 10 modules by default
        initialExpandedState.set(module._id, index < 10)
      })

      // Only set the initial state if we haven't set it before
      setExpandedModules(prev => {
        // If we already have state for any modules, don't override it
        if (prev.size > 0) {
          // Add any new modules that aren't in the previous state
          const newState = new Map(prev)
          allModules.forEach((module, index) => {
            if (!newState.has(module._id)) {
              // New modules default to collapsed unless they're in the first 10
              newState.set(module._id, index < 10)
            }
          })
          return newState
        }
        return initialExpandedState
      })
    }
  }, [data])

  const handleMoveItem = (
    dragIndex: number,
    hoverIndex: number,
    dragModuleId: string,
    hoverModuleId: string,
  ) => {
    // Get the current data for the source module
    const sourceModuleData = queryClient.getQueryData(['moduleItems', dragModuleId]) as any
    if (!sourceModuleData?.moduleItems?.length) return

    // Get the item being moved
    const movedItem = sourceModuleData.moduleItems[dragIndex]
    if (!movedItem) return

    // We're using the shared utility functions from dndUtils.ts

    // Helper to update cache and call the mutation
    const updateAndMutate = (moduleId: string, oldModuleId: string, updatedItems: any[]) => {
      // Update cache
      queryClient.setQueryData(['moduleItems', moduleId], {
        ...(moduleId === dragModuleId
          ? sourceModuleData
          : queryClient.getQueryData(['moduleItems', moduleId])),
        moduleItems: updatedItems,
      })

      // Get item IDs and call mutation if needed
      const itemIds = getItemIds(updatedItems)
      if (itemIds.length > 0) {
        reorderItemsMutation.mutate({
          courseId,
          moduleId,
          oldModuleId,
          order: itemIds,
        })
      }
    }

    // ---------- STEP 1: OPTIMISTIC UI UPDATE ----------
    // For same-module reordering
    if (dragModuleId === hoverModuleId) {
      // Clone and update the module items
      const updatedItems = [...sourceModuleData.moduleItems]
      updatedItems.splice(dragIndex, 1) // Remove from old position
      updatedItems.splice(hoverIndex, 0, movedItem) // Insert at new position

      // Update all indexes and update cache
      updateAndMutate(dragModuleId, dragModuleId, updateIndexes(updatedItems))
    }
    // For cross-module movement
    else {
      // Get destination module data
      const destModuleData = queryClient.getQueryData(['moduleItems', hoverModuleId]) as any
      if (!destModuleData?.moduleItems) return

      // Prepare source module update (remove the item)
      const updatedSourceItems = updateIndexes(
        sourceModuleData.moduleItems.filter((_: any, i: number) => i !== dragIndex),
      )

      // Prepare destination module update (add the item)
      const updatedItem = {
        ...movedItem,
        moduleId: hoverModuleId,
        index: hoverIndex,
      }
      const updatedDestItems = [...destModuleData.moduleItems]
      updatedDestItems.splice(hoverIndex, 0, updatedItem)
      const updatedDestWithIndexes = updateIndexes(updatedDestItems)

      // Update both caches and call mutations
      updateAndMutate(dragModuleId, dragModuleId, updatedSourceItems)
      updateAndMutate(hoverModuleId, dragModuleId, updatedDestWithIndexes)
    }
  }

  // Use the utility function from dndUtils.ts, passing our handleMoveItem as a callback
  const handleDragEnd = (result: DropResult) => {
    // Check for no destination or no movement first
    if (
      !result.destination ||
      (result.source.droppableId === result.destination.droppableId &&
        result.source.index === result.destination.index)
    ) {
      return
    }

    // Use the shared utility function
    dndHandleDragEnd(
      result,
      data,
      courseId || '',
      queryClient,
      reorderModulesMutation,
      handleMoveItem,
    )
  }

  const handleCollapseAllRef = useCallback(() => {
    handleCollapseAll(data, setExpandedModules)
  }, [data, setExpandedModules])

  const handleExpandAllRef = useCallback(() => {
    handleExpandAll(data, setExpandedModules)
  }, [data, setExpandedModules])

  const onToggleExpandRef = useCallback(
    (moduleId: string) => {
      handleToggleExpand(moduleId, setExpandedModules)
    },
    [setExpandedModules],
  )

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <View as="div">
        <ModulePageActionHeader
          onCollapseAll={handleCollapseAllRef}
          onExpandAll={handleExpandAllRef}
          anyModuleExpanded={Array.from(expandedModules.values()).some(expanded => expanded)}
        />
        {isLoading && !data ? (
          <View as="div" textAlign="center" padding="large">
            <Spinner renderTitle={I18n.t('Loading modules')} size="large" />
          </View>
        ) : error ? (
          <View as="div" textAlign="center" padding="large">
            <Text color="danger">{I18n.t('Error loading modules')}</Text>
          </View>
        ) : (
          <Droppable droppableId="modules-list" type="MODULE">
            {provided => (
              <div
                ref={provided.innerRef}
                {...provided.droppableProps}
                style={{minHeight: '100px'}}
              >
                <Flex direction="column" gap="small">
                  {data?.pages[0]?.modules.length === 0 ? (
                    <View as="div" textAlign="center" padding="large">
                      <Text>{I18n.t('No modules found')}</Text>
                    </View>
                  ) : (
                    data?.pages
                      .flatMap(page => page.modules)
                      .map((module, index) => (
                        <Draggable key={module._id} draggableId={module._id} index={index}>
                          {(dragProvided, snapshot) => (
                            <div
                              ref={dragProvided.innerRef}
                              {...dragProvided.draggableProps}
                              style={{
                                ...dragProvided.draggableProps.style,
                                margin: '0 0 8px 0',
                                background: snapshot.isDragging ? '#F2F4F4' : 'transparent',
                                borderRadius: '4px',
                              }}
                            >
                              <MemoizedModule
                                id={module._id}
                                name={module.name}
                                published={module.published}
                                prerequisites={module.prerequisites}
                                completionRequirements={module.completionRequirements}
                                requirementCount={module.requirementCount}
                                expanded={!!expandedModules.get(module._id)}
                                hasActiveOverrides={module.hasActiveOverrides}
                                onToggleExpand={onToggleExpandRef}
                                dragHandleProps={dragProvided.dragHandleProps}
                                setModuleAction={setModuleAction}
                                setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
                                setSelectedModuleItem={setSelectedModuleItem}
                                setSourceModule={setSourceModule}
                              />
                            </div>
                          )}
                        </Draggable>
                      ))
                  )}
                </Flex>
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        )}
        {isManageModuleContentTrayOpen && (
          <ManageModuleContentTray
            sourceModuleId={sourceModule?.id || ''}
            sourceModuleTitle={sourceModule?.title || ''}
            sourceModuleItemId={selectedModuleItem?.id}
            isOpen={isManageModuleContentTrayOpen}
            onClose={() => {
              setIsManageModuleContentTrayOpen(false)
              setModuleAction(null)
              setSelectedModuleItem(null)
            }}
            moduleAction={moduleAction}
            moduleItemId={selectedModuleItem?.id}
            moduleItemTitle={selectedModuleItem?.title}
          />
        )}
      </View>
    </DragDropContext>
  )
}

export default ModulesList
