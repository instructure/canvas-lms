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

import React, {useState, useEffect, useCallback} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import ModulePageActionHeader from './ModulePageActionHeader'
import Module from './Module'
import AddItemModal from '../components/AddItemModal'
import {DragDropContext, Droppable, Draggable, DropResult} from 'react-beautiful-dnd'
import {
  handleCollapseAll,
  handleExpandAll,
  handleToggleExpand,
  handleOpeningModuleUpdateTray,
} from '../handlers/modulePageActionHandlers'

import {useModules} from '../hooks/queries/useModules'
import {useReorderModuleItems} from '../hooks/mutations/useReorderModuleItems'
import {useReorderModules} from '../hooks/mutations/useReorderModules'
import {useContextModule} from '../hooks/useModuleContext'
import {queryClient} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import { handleMoveItem as dndHandleMoveItem, handleDragEnd as dndHandleDragEnd } from '../utils/dndUtils'

const I18n = createI18nScope('context_modules_v2')

const ModulesList: React.FC = () => {
  const {courseId} = useContextModule()
  const reorderItemsMutation = useReorderModuleItems()
  const reorderModulesMutation = useReorderModules()
  const {data, isLoading, error} = useModules(courseId || '')

  // Initialize with an empty Map - all modules will be collapsed by default
  const [expandedModules, setExpandedModules] = useState<Map<string, boolean>>(new Map())
  const [isAddItemModalOpen, setIsAddItemModalOpen] = useState<boolean>(false)
  const [selectedModuleId, setSelectedModuleId] = useState<string>('')
  const [selectedModuleName, setSelectedModuleName] = useState<string>('')

  // Set initial expanded state for modules when data is loaded
  useEffect(() => {
    if (data?.pages) {
      const allModules = data.pages.flatMap(page => page.modules)

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
  }, [data?.pages])

  const handleMoveItem = (dragIndex: number, hoverIndex: number, dragModuleId: string, hoverModuleId: string) => {
    dndHandleMoveItem(
      dragIndex,
      hoverIndex,
      dragModuleId,
      hoverModuleId,
      data,
      courseId,
      reorderItemsMutation
    )
  }

  const handleDragEnd = (result: DropResult) => {
    dndHandleDragEnd(
      result,
      data,
      courseId,
      queryClient,
      reorderModulesMutation,
      handleMoveItem
    )
  }

  const handleCollapseAllRef = useCallback(() => {
    handleCollapseAll(data, setExpandedModules)
  }, [data, setExpandedModules])

  const handleExpandAllRef = useCallback(() => {
    handleExpandAll(data, setExpandedModules)
  }, [data, setExpandedModules])

  const handleOpeningModuleUpdateTrayRef = useCallback((moduleId?: string,
    moduleName?: string,
    prerequisites?: {id: string, name: string, type: string}[],
    openTab: 'settings' | 'assign-to' = 'settings') => (
      handleOpeningModuleUpdateTray(data, courseId, moduleId, moduleName, prerequisites, openTab)
    ), [handleOpeningModuleUpdateTray, data])

  const handleViewProgressRef = useCallback(() => {
    window.location.href = `/courses/${courseId}/modules/progressions`
  }, [])

  const handleOnCloseRequestRef = useCallback(() => {
    setIsAddItemModalOpen(false)
  }, [setIsAddItemModalOpen])

  const onAddItemRef = useCallback((id: string, name: string) => {
    setIsAddItemModalOpen(true)
    setSelectedModuleId(id)
    setSelectedModuleName(name)
  }, [setIsAddItemModalOpen, setSelectedModuleId, setSelectedModuleName])

  const onToggleExpandRef = useCallback((moduleId: string) => {
    handleToggleExpand(moduleId, setExpandedModules)
  }, [handleToggleExpand, setExpandedModules])

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <View as="div" margin="medium">
        <ModulePageActionHeader
          onCollapseAll={handleCollapseAllRef}
          onExpandAll={handleExpandAllRef}
          onViewProgress={handleViewProgressRef}
          handleOpeningModuleUpdateTray={handleOpeningModuleUpdateTrayRef}
          anyModuleExpanded={Array.from(expandedModules.values()).some(expanded => expanded)}
        />
        <AddItemModal
          isOpen={isAddItemModalOpen}
          onRequestClose={handleOnCloseRequestRef}
          moduleName={selectedModuleName}
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
            {(provided) => (
              <div
                ref={provided.innerRef}
                {...provided.droppableProps}
                style={{ minHeight: '100px' }}
              >
                <Flex direction="column" gap="small">
                {data?.pages[0]?.modules.length === 0 ? (
                    <View as="div" textAlign="center" padding="large">
                      <Text>{I18n.t('No modules found')}</Text>
                    </View>
                  ) : (
                  data?.pages.flatMap(page => page.modules).map((module, index) => (
                    <Draggable key={module._id} draggableId={module._id} index={index}>
                      {(dragProvided, snapshot) => (
                        <div
                          ref={dragProvided.innerRef}
                          {...dragProvided.draggableProps}
                          style={{
                            ...dragProvided.draggableProps.style,
                            margin: '0 0 8px 0',
                            background: snapshot.isDragging ? '#f5f5f5' : 'transparent',
                            borderRadius: '4px'
                          }}
                        >
                          <Module
                            id={module._id}
                            name={module.name}
                            published={module.published}
                            prerequisites={module.prerequisites}
                            completionRequirements={module.completionRequirements}
                            requirementCount={module.requirementCount}
                            handleOpeningModuleUpdateTray={handleOpeningModuleUpdateTrayRef}
                            expanded={!!expandedModules.get(module._id)}
                            onToggleExpand={onToggleExpandRef}
                            dragHandleProps={dragProvided.dragHandleProps}
                            onAddItem={onAddItemRef}
                          />
                        </div>
                      )}
                    </Draggable>
                  )))}
                </Flex>
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        )}
      </View>
    </DragDropContext>
  )
}

export default ModulesList
