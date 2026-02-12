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

import React from 'react'
import type {Root} from 'react-dom/client'
import {render} from '@canvas/react'
import {Module as ModuleType} from '@canvas/context-modules/differentiated-modules/react/types'
import DifferentiatedModulesTray from '@canvas/context-modules/differentiated-modules/react/DifferentiatedModulesTray'
import {queryClient} from '@canvas/query'
import {InfiniteData} from '@tanstack/react-query'
import type {
  HTMLElementWithRoot,
  ModuleItem,
  ModulesResponse,
  PaginatedNavigationResponse,
} from '../utils/types'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {MODULE_ITEMS, MODULES} from '../utils/constants'
import EditItemModal from '../componentsTeacher/EditItemModal'

export const handleCollapseAll = (
  data: InfiniteData<ModulesResponse> | undefined,
  setExpandedModules: React.Dispatch<React.SetStateAction<Map<string, boolean>>>,
) => {
  if (data?.pages) {
    const allModules = data.pages.flatMap(page => page.modules)
    const newState = new Map<string, boolean>()
    allModules.forEach(module => {
      newState.set(module._id, false)
    })
    setExpandedModules(newState)
  }
}

export const handleExpandAll = (
  data: InfiniteData<ModulesResponse> | undefined,
  setExpandedModules: React.Dispatch<React.SetStateAction<Map<string, boolean>>>,
) => {
  if (data?.pages) {
    const allModules = data.pages.flatMap(page => page.modules)
    const newState = new Map<string, boolean>()
    allModules.forEach(module => {
      newState.set(module._id, true)
    })
    setExpandedModules(newState)
  }
}

export const handleToggleExpand = (
  moduleId: string,
  setExpandedModules: React.Dispatch<React.SetStateAction<Map<string, boolean>>>,
) => {
  setExpandedModules(prev => {
    const newState = new Map(prev)
    newState.set(moduleId, !prev.get(moduleId))
    return newState
  })
}

const getResourceType = (type?: string): string => {
  if (!type) return 'assignment'

  switch (type) {
    case 'quiz':
      return 'quiz'
    case 'discussion':
      return 'discussion'
    case 'attachment':
    case 'file':
      return 'file'
    case 'wiki_page':
    case 'page':
      return 'page'
    case 'externalurl':
      return 'externalUrl'
    case 'context_external_tool':
    case 'moduleexternaltool':
    case 'externaltool':
      return 'externalTool'
    default:
      return 'assignment'
  }
}

const requirementTypeMap: Record<string, string> = {
  must_submit: 'submit',
  must_view: 'view',
  must_mark_done: 'mark',
  must_contribute: 'contribute',
  min_score: 'score',
  min_percentage: 'percentage',
}

const getModuleItemsFromAvailableSources = (
  providedModuleItems: Partial<ModuleItem>[],
  currentModule?: any,
): any[] => {
  if (providedModuleItems.length > 0) {
    return providedModuleItems
  }

  if (
    currentModule &&
    Array.isArray(currentModule.moduleItems) &&
    currentModule.moduleItems.length > 0
  ) {
    return currentModule.moduleItems
  }

  return []
}

export const transformModuleItemsForTray = (rawModuleItems: any[]): any[] => {
  // Filter out SubHeader items as they shouldn't be selectable in the requirements selector
  return rawModuleItems
    .filter((item: any) => item.content?.type !== 'SubHeader')
    .map((item: any) => ({
      id: item._id || '',
      name: item.title || '',
      resource: item.content?.isNewQuiz
        ? 'quiz'
        : getResourceType(item.content?.type?.toLowerCase()),
      graded: item.content?.graded,
      pointsPossible: item.content?.pointsPossible ? String(item.content.pointsPossible) : '',
    }))
}

export const transformRequirementsForTray = (
  completionRequirements: any[] = [],
  moduleItems: any[],
  rawModuleItems: any[],
): any[] => {
  return completionRequirements.map(req => {
    const moduleItem = moduleItems.find((item: {id: string}) => item.id === req.id)

    const rawModuleItem = rawModuleItems.find(
      (item: {id?: string; _id?: string}) => item.id === req.id || item._id === req.id,
    )

    const mappedType = requirementTypeMap[req.type] || req.type

    return {
      id: req.id,
      name: moduleItem?.name || '',
      type: mappedType,
      resource: moduleItem?.resource || 'assignment',
      graded: rawModuleItem?.content?.graded,
      pointsPossible:
        moduleItem?.pointsPossible || String(rawModuleItem?.content?.pointsPossible || 0),
      minimumScore: req.minScore ? String(req.minScore) : '0',
    }
  })
}

const getDifferentiatedModulesMountPoint = (): HTMLElement => {
  let mountPoint = document.getElementById('differentiated-modules-mount-point')
  if (!mountPoint) {
    mountPoint = document.createElement('div')
    mountPoint.id = 'differentiated-modules-mount-point'
    document.body.appendChild(mountPoint)
  }
  return mountPoint
}

export const handleOpeningModuleUpdateTray = (
  data: InfiniteData<ModulesResponse> | undefined,
  courseId: string,
  moduleId?: string,
  moduleName?: string,
  openTab: 'settings' | 'assign-to' = 'settings',
  providedModuleItems: Partial<ModuleItem>[] = [],
) => {
  const moduleElement = document.createElement('div')
  moduleElement.id = moduleId ? `context_module_${moduleId}` : 'context_module_new'
  moduleElement.style.display = 'none'
  document.getElementById('context_modules_sortable_container')?.appendChild(moduleElement)

  const moduleList: ModuleType[] =
    data?.pages
      .flatMap(page => page.modules)
      .map(module => ({
        id: module._id,
        name: module.name,
      })) || []

  const currentModule = moduleId
    ? data?.pages.flatMap(page => page.modules).find(module => module._id === moduleId)
    : undefined

  const prerequisites = currentModule?.prerequisites || []
  const rawModuleItems = getModuleItemsFromAvailableSources(providedModuleItems, currentModule)
  const moduleItems = transformModuleItemsForTray(rawModuleItems)
  const requirementCount = currentModule?.requirementCount === 1 ? 'one' : 'all'
  const requirements = currentModule?.completionRequirements
    ? transformRequirementsForTray(
        currentModule.completionRequirements,
        moduleItems,
        rawModuleItems,
      )
    : []

  const mountPoint = getDifferentiatedModulesMountPoint()
  let root: Root | null = null

  const onCompleteFunction = () =>
    queryClient.invalidateQueries({queryKey: [MODULES, courseId || '']})
  const trayProps = {
    onDismiss: () => {
      root?.unmount()
      const addButton = document.querySelector('.add-module-button') as HTMLElement
      addButton?.focus()
    },
    initialTab: openTab,
    moduleElement,
    courseId,
    moduleList,
    moduleId,
    moduleName,
    prerequisites,
    onComplete: onCompleteFunction,
    onChangeAssignedTo: onCompleteFunction,
    // Additional props needed by SettingsPanel
    moduleItems,
    requirementCount,
    requirements,
    requireSequentialProgress: currentModule?.requireSequentialProgress || false,
    publishFinalGrade: false,
    unlockAt: currentModule?.unlockAt,
    published: currentModule?.published || false,
  }

  root = render(<DifferentiatedModulesTray {...(trayProps as any)} />, mountPoint)
}

export const handleOpeningEditItemModal = (
  courseId: string,
  moduleId: string,
  moduleItemId: string,
) => {
  const queries = queryClient.getQueriesData<PaginatedNavigationResponse>({
    queryKey: [MODULE_ITEMS, moduleId],
  })

  let moduleItem: ModuleItem | null = null
  for (const [, data] of queries) {
    if (!data) continue
    const found = data.moduleItems?.find((i: any) => i._id === moduleItemId)
    if (found) {
      moduleItem = found
      break
    }
  }
  if (!moduleItem) return
  const itemProps = {
    courseId,
    itemName: moduleItem.title,
    itemURL: moduleItem.moduleItemUrl ?? undefined,
    itemNewTab: moduleItem.newTab,
    itemIndent: moduleItem.indent,
    moduleId: moduleId,
    itemId: moduleItem._id,
    itemType: moduleItem.content?.type?.toLowerCase(),
    masterCourseRestrictions: moduleItem.masterCourseRestrictions,
  }

  const mountPoint = document.getElementById('module-item-mount-point') as HTMLElementWithRoot
  let root = mountPoint.reactRoot

  const onRequestClose = () => {
    root?.render(<EditItemModal {...itemProps} isOpen={false} onRequestClose={onRequestClose} />)
  }

  if (!root) {
    root = render(
      <EditItemModal {...itemProps} isOpen={true} onRequestClose={onRequestClose} />,
      mountPoint,
    )
    mountPoint.reactRoot = root
  } else {
    root.render(<EditItemModal {...itemProps} isOpen={true} onRequestClose={onRequestClose} />)
  }
}

export const handleAddItem = (
  moduleId: string,
  data: InfiniteData<ModulesResponse> | undefined,
  setSelectedModuleId: React.Dispatch<React.SetStateAction<string>>,
  setSelectedModuleName: React.Dispatch<React.SetStateAction<string>>,
  setIsAddItemModalOpen: React.Dispatch<React.SetStateAction<boolean>>,
) => {
  const module = data?.pages.flatMap(page => page.modules).find(m => m._id === moduleId)
  if (module) {
    setSelectedModuleId(moduleId)
    setSelectedModuleName(module.name)
    setIsAddItemModalOpen(true)
  }
}

export const handleModuleViewChange = async (
  role: 'teacher' | 'student',
  setValue: React.Dispatch<React.SetStateAction<string>>,
  courseId: string,
  data: {id?: string},
) => {
  const {id} = data
  const moduleId = id ?? 'all'
  setValue(moduleId)

  try {
    await doFetchApi({
      path: `/api/v1/courses/${courseId}/settings`,
      method: 'PUT',
      body: {
        [`show_${role}_only_module_id`]: moduleId,
      },
    })
  } catch (err: any) {
    showFlashError(`Cannot set the ${role} view module: ${err.message}`)
  }
}
