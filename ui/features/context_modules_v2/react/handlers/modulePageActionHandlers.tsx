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
import {createRoot} from 'react-dom/client'
import {Module as ModuleType} from '@canvas/context-modules/differentiated-modules/react/types'
import DifferentiatedModulesTray from '@canvas/context-modules/differentiated-modules/react/DifferentiatedModulesTray'
import {queryClient} from '@canvas/query'
import {InfiniteData} from '@tanstack/react-query'
import type {ModuleItem, ModulesResponse} from '../utils/types'

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
  providedModuleItems: ModuleItem[],
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

const transformModuleItemsForTray = (rawModuleItems: any[]): any[] => {
  // Filter out SubHeader items as they shouldn't be selectable in the requirements selector
  return rawModuleItems
    .filter((item: any) => item.content?.type !== 'SubHeader')
    .map((item: any) => ({
      id: item._id || '',
      name: item.content?.title || '',
      resource: getResourceType(item.content?.type.toLowerCase()),
      graded: item.content?.graded,
      pointsPossible: item.content?.pointsPossible ? String(item.content.pointsPossible) : '',
    }))
}

const transformRequirementsForTray = (
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
  prerequisites?: {id: string; name: string; type: string}[],
  openTab: 'settings' | 'assign-to' = 'settings',
  providedModuleItems: ModuleItem[] = [],
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
  const root = createRoot(mountPoint)

  const onCompleteFunction = () =>
    queryClient.invalidateQueries({queryKey: ['modules', courseId || '']})
  const trayProps = {
    onDismiss: () => {
      root.unmount()
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
  }

  root.render(<DifferentiatedModulesTray {...(trayProps as any)} />)
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
