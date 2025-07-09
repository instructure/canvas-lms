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

import React, {useState, useEffect, useCallback, memo, useMemo} from 'react'
import {debounce} from '@instructure/debounce'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import ModulePageActionHeader from './ModulePageActionHeader'
import Module from './Module'
import {DragDropContext, Droppable, Draggable, DropResult} from 'react-beautiful-dnd'
import {
  handleCollapseAll,
  handleExpandAll,
  handleModuleViewChange,
} from '../handlers/modulePageActionHandlers'
import ManageModuleContentTray from './ManageModuleContent/ManageModuleContentTray'
import {useModules} from '../hooks/queries/useModules'
import {useReorderModuleItems} from '../hooks/mutations/useReorderModuleItems'
import {useReorderModules} from '../hooks/mutations/useReorderModules'
import {useToggleCollapse, useToggleAllCollapse} from '../hooks/mutations/useToggleCollapse'
import {useContextModule} from '../hooks/useModuleContext'
import {queryClient} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleAction, ModuleItem} from '../utils/types'
import {updateIndexes, getItemIds, handleDragEnd as dndHandleDragEnd} from '../utils/dndUtils'
import ModuleFilterHeader from './ModuleFilterHeader'
import {useCourseTeacher} from '../hooks/queriesTeacher/useCourseTeacher'
import {validateModuleTeacherRenderRequirements, ALL_MODULES} from '../utils/utils'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useHowManyModulesAreFetchingItems} from '../hooks/queries/useHowManyModulesAreFetchingItems'
import {TEACHER, STUDENT, MODULE_ITEMS} from '../utils/constants'

const I18n = createI18nScope('context_modules_v2')

const MemoizedModule = memo(Module, validateModuleTeacherRenderRequirements)

const ModulesList: React.FC = () => {
  const {
    teacherViewEnabled,
    studentViewEnabled,
    courseId,
    moduleCursorState,
    setModuleCursorState,
  } = useContextModule()
  const reorderItemsMutation = useReorderModuleItems()
  const reorderModulesMutation = useReorderModules()
  const {data, isLoading, error} = useModules(courseId || '')
  const {moduleFetchingCount, maxFetchingCount, fetchComplete} = useHowManyModulesAreFetchingItems()
  const toggleCollapseMutation = useToggleCollapse(courseId || '')
  const toggleAllCollapse = useToggleAllCollapse(courseId || '')

  // Initialize with an empty Map - all modules will be collapsed by default
  const [expandedModules, setExpandedModules] = useState<Map<string, boolean>>(new Map())

  // State for managing the module content tray
  const [isManageModuleContentTrayOpen, setIsManageModuleContentTrayOpen] = useState(false)
  const [moduleAction, setModuleAction] = useState<ModuleAction | null>(null)
  const [selectedModuleItem, setSelectedModuleItem] = useState<{id: string; title: string} | null>(
    null,
  )
  const [sourceModule, setSourceModule] = useState<{id: string; title: string} | null>(null)
  const [teacherViewValue, setTeacherViewValue] = useState(ALL_MODULES)
  const [studentViewValue, setStudentViewValue] = useState(ALL_MODULES)
  const {data: courseStudentData} = useCourseTeacher(courseId || '')
  const [isDisabled, setIsDisabled] = useState(true)

  useEffect(() => {
    setIsDisabled(moduleFetchingCount > 0)
  }, [moduleFetchingCount])

  useEffect(() => {
    if ((!teacherViewEnabled && !studentViewEnabled) || !courseStudentData) return

    const studentId = courseStudentData.settings?.showStudentOnlyModuleId ?? ALL_MODULES
    const teacherId = courseStudentData.settings?.showTeacherOnlyModuleId ?? ALL_MODULES

    setStudentViewValue(studentId)
    setTeacherViewValue(teacherId)
  }, [courseId, teacherViewEnabled, studentViewEnabled, courseStudentData])

  const moduleOptions = useMemo(() => {
    if (!data) return {teacherView: [], studentView: []}

    const allModules = data.pages.flatMap(page =>
      page.modules.map(m => ({
        id: m._id,
        name: m.name,
        published: m.published,
      })),
    )

    return {
      teacherView: allModules,
      studentView: allModules.filter(m => m.published),
    }
  }, [data])

  const handleTeacherChange = (
    _e: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number; id?: string},
  ) => handleModuleViewChange(TEACHER, setTeacherViewValue, courseId, data)

  const handleStudentChange = (
    _e: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number; id?: string},
  ) => handleModuleViewChange(STUDENT, setStudentViewValue, courseId, data)

  // Set initial expanded state for modules when data is loaded
  useEffect(() => {
    if (data?.pages) {
      const allModules = data.pages.flatMap(page => page.modules)

      // Create a Map for module expansion state
      const initialExpandedState = new Map<string, boolean>()
      allModules.forEach(module => {
        // Use collapsed state from progression if available
        if (module.progression && module.progression?.collapsed !== null) {
          // Note: we invert collapsed to get expanded state
          initialExpandedState.set(module._id, !module.progression.collapsed)
        } else {
          // Default all modules to collapsed
          initialExpandedState.set(module._id, false)
        }
      })

      setExpandedModules(prev => {
        if (prev.size > 0) {
          const newState = new Map(prev)
          allModules.forEach(module => {
            if (!newState.has(module._id)) {
              // For newly added modules, respect their progression collapsed state
              if (module.progression && module.progression.collapsed !== null) {
                newState.set(module._id, !module.progression.collapsed)
              } else {
                newState.set(module._id, false) // Default to collapsed
              }
            }
          })
          return newState
        }
        return initialExpandedState
      })

      setModuleCursorState(
        Object.fromEntries(
          allModules.map(module => [module._id, moduleCursorState[module._id] ?? null]),
        ),
      )
    }
  }, [data?.pages, setModuleCursorState])

  useEffect(() => {
    if (fetchComplete && maxFetchingCount > 1) {
      requestAnimationFrame(() => {
        showFlashAlert({
          message: 'All module items loaded',
          type: 'success',
          srOnly: true,
          politeness: 'assertive',
        })
      })
    }
  }, [maxFetchingCount, fetchComplete])

  const handleMoveItem = (
    dragIndex: number,
    hoverIndex: number,
    dragModuleId: string,
    hoverModuleId: string,
  ) => {
    const dragCursor = moduleCursorState[dragModuleId]
    const hoverCursor = moduleCursorState[hoverModuleId]

    const sourceModuleData = queryClient.getQueryData([MODULE_ITEMS, dragModuleId, dragCursor]) as {
      moduleItems: ModuleItem[]
    }

    if (!sourceModuleData?.moduleItems?.length) return

    // Get the item being moved
    const movedItem = sourceModuleData.moduleItems[dragIndex]
    if (!movedItem) return

    // Helper to update cache and call the mutation
    const updateAndMutate = (moduleId: string, oldModuleId: string, updatedItems: ModuleItem[]) => {
      // Update cache
      const cursor = moduleCursorState[moduleId]

      queryClient.setQueryData([MODULE_ITEMS, moduleId, cursor], {
        ...(moduleId === dragModuleId
          ? sourceModuleData
          : queryClient.getQueryData([MODULE_ITEMS, moduleId, cursor])),
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
      // For cross-module movement
    } else {
      const destModuleData = queryClient.getQueryData([
        MODULE_ITEMS,
        hoverModuleId,
        hoverCursor,
      ]) as {
        moduleItems: ModuleItem[]
      }

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

  // Create debounced function for individual module toggle
  const debouncedToggleCollapse = useCallback(() => {
    const debouncedFn = debounce((params: {moduleId: string; collapse: boolean}) => {
      toggleCollapseMutation.mutate(params)
    }, 500)

    return debouncedFn
  }, [toggleCollapseMutation])() // Execute immediately to get the debounced function

  // Clean up debounced functions on unmount
  useEffect(() => {
    return () => {
      // Cancel any pending debounced calls
      debouncedToggleCollapse.cancel()
    }
  }, [debouncedToggleCollapse])

  const handleToggleAllCollapse = useCallback(
    (collapse: boolean) => {
      toggleAllCollapse.mutate(collapse)
    },
    [toggleAllCollapse],
  )

  const handleCollapseAllRef = useCallback(() => {
    // Update UI immediately
    handleCollapseAll(data, setExpandedModules)
    // Persist to database
    handleToggleAllCollapse(true)
  }, [data, setExpandedModules, handleToggleAllCollapse])

  const handleExpandAllRef = useCallback(() => {
    // Update UI immediately
    handleExpandAll(data, setExpandedModules)
    // Persist to database
    handleToggleAllCollapse(false)
  }, [data, setExpandedModules, handleToggleAllCollapse])

  const onToggleExpandRef = useCallback(
    (moduleId: string) => {
      const currentExpanded = expandedModules.get(moduleId) || false

      // Update UI immediately for responsiveness
      setExpandedModules(prev => {
        const newState = new Map(prev)
        newState.set(moduleId, !currentExpanded)
        return newState
      })

      // Debounce the API call to persist the collapsed state
      // Note: the endpoint expects 'collapse' which is the opposite of 'expanded'
      debouncedToggleCollapse({
        moduleId,
        collapse: currentExpanded, // If currently expanded, we're collapsing it
      })
    },
    [expandedModules, debouncedToggleCollapse],
  )

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <View as="div">
        <ModulePageActionHeader
          onCollapseAll={handleCollapseAllRef}
          onExpandAll={handleExpandAllRef}
          anyModuleExpanded={Array.from(expandedModules.values()).some(expanded => expanded)}
          disabled={isDisabled}
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
                {(studentViewEnabled || teacherViewEnabled) && data?.pages ? (
                  <ModuleFilterHeader
                    moduleOptions={moduleOptions}
                    handleTeacherChange={handleTeacherChange}
                    teacherViewValue={teacherViewValue}
                    teacherViewEnabled={teacherViewEnabled}
                    handleStudentChange={handleStudentChange}
                    studentViewValue={studentViewValue}
                    studentViewEnabled={studentViewEnabled}
                    disabled={isDisabled}
                  />
                ) : null}
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
                                display:
                                  !teacherViewValue ||
                                  module._id === teacherViewValue ||
                                  teacherViewValue === ALL_MODULES
                                    ? 'block'
                                    : 'none',
                              }}
                            >
                              <MemoizedModule
                                id={module._id}
                                name={module.name}
                                published={module.published}
                                prerequisites={module.prerequisites}
                                completionRequirements={module.completionRequirements}
                                requirementCount={module.requirementCount}
                                unlockAt={module.unlockAt}
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
