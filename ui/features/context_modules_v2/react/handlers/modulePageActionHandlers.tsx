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
import { createRoot } from 'react-dom/client'
import { Module as ModuleType } from '@canvas/context-modules/differentiated-modules/react/types'
import DifferentiatedModulesTray from '@canvas/context-modules/differentiated-modules/react/DifferentiatedModulesTray'
import { queryClient } from '@canvas/query'
import { InfiniteData } from '@tanstack/react-query'
import type { ModulesResponse } from '../utils/types'

export const handleCollapseAll = (
  data: InfiniteData<ModulesResponse> | undefined,
  setExpandedModules: React.Dispatch<React.SetStateAction<Map<string, boolean>>>
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
  setExpandedModules: React.Dispatch<React.SetStateAction<Map<string, boolean>>>
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
  setExpandedModules: React.Dispatch<React.SetStateAction<Map<string, boolean>>>
) => {
  setExpandedModules(prev => {
    const newState = new Map(prev)
    newState.set(moduleId, !prev.get(moduleId))
    return newState
  })
}

export const handleOpeningModuleUpdateTray = (
  data: InfiniteData<ModulesResponse> | undefined,
  courseId: string,
  moduleId?: string,
  moduleName?: string,
  prerequisites?: {id: string, name: string, type: string}[],
  openTab: 'settings' | 'assign-to' = 'settings'
) => {
  const moduleElement = document.createElement('div')
  moduleElement.id = moduleId ? `context_module_${moduleId}` : 'context_module_new'
  moduleElement.style.display = 'none'
  document.getElementById('context_modules_sortable_container')?.appendChild(moduleElement)

  const moduleList: ModuleType[] = data?.pages.flatMap(page => page.modules).map(module => ({
    id: module._id,
    name: module.name
  })) || []

  const onComplete = () => {
    queryClient.invalidateQueries({ queryKey: ['modules', courseId || ''] })
  }

  const container = document.getElementById('differentiated-modules-mount-point')
  if (!container) {
    const mountPoint = document.createElement('div')
    mountPoint.id = 'differentiated-modules-mount-point'
    document.body.appendChild(mountPoint)
  }

  const mountPoint = document.getElementById('differentiated-modules-mount-point')!
  const root = createRoot(mountPoint)

  root.render(
    <DifferentiatedModulesTray
      onDismiss={() => {
        root.unmount()
        const addButton = document.querySelector('.add-module-button') as HTMLElement
        addButton?.focus()
      }}
      initialTab={openTab}
      moduleElement={moduleElement}
      courseId={courseId}
      moduleList={moduleList}
      moduleId={moduleId ?? undefined}
      moduleName={moduleName ?? undefined}
      prerequisites={prerequisites}
      onComplete={onComplete}
    />
  )
}

export const handleAddItem = (
  moduleId: string,
  data: InfiniteData<ModulesResponse> | undefined,
  setSelectedModuleId: React.Dispatch<React.SetStateAction<string>>,
  setSelectedModuleName: React.Dispatch<React.SetStateAction<string>>,
  setIsAddItemModalOpen: React.Dispatch<React.SetStateAction<boolean>>
) => {
  const module = data?.pages.flatMap(page => page.modules).find(m => m._id === moduleId)
  if (module) {
    setSelectedModuleId(moduleId)
    setSelectedModuleName(module.name)
    setIsAddItemModalOpen(true)
  }
}
