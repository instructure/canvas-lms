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

import {createContext, useContext, useState} from 'react'
import {
  ExternalTool,
  ModuleCursorState,
  MenuAction,
  MenuItemActionState,
  PerModuleState,
} from '../utils/types'

const ContextModule = createContext<{
  courseId: string
  isMasterCourse: boolean
  isChildCourse: boolean
  permissions: Record<string, boolean>
  NEW_QUIZZES_BY_DEFAULT: boolean
  DEFAULT_POST_TO_SIS: boolean
  teacherViewEnabled: boolean
  studentViewEnabled: boolean
  restrictQuantitativeData: boolean
  isObserver: boolean
  observedStudent: {id: string; name: string} | null
  externalTools: ExternalTool[]
  moduleMenuModalTools: ExternalTool[]
  moduleGroupMenuTools: ExternalTool[]
  moduleMenuTools: ExternalTool[]
  moduleIndexMenuModalTools: ExternalTool[]
  menuItemLoadingState: PerModuleState<MenuItemActionState>
  setMenuItemLoadingState: React.Dispatch<React.SetStateAction<PerModuleState<MenuItemActionState>>>
  moduleCursorState: ModuleCursorState
  setModuleCursorState: React.Dispatch<React.SetStateAction<ModuleCursorState>>
  modulesArePaginated: boolean
  pageSize: number
}>(
  {} as {
    courseId: string
    isMasterCourse: boolean
    isChildCourse: boolean
    permissions: Record<string, boolean>
    NEW_QUIZZES_BY_DEFAULT: boolean
    DEFAULT_POST_TO_SIS: boolean
    teacherViewEnabled: boolean
    studentViewEnabled: boolean
    restrictQuantitativeData: boolean
    isObserver: boolean
    observedStudent: {id: string; name: string} | null
    externalTools: ExternalTool[]
    moduleMenuModalTools: ExternalTool[]
    moduleGroupMenuTools: ExternalTool[]
    moduleMenuTools: ExternalTool[]
    moduleIndexMenuModalTools: ExternalTool[]
    menuItemLoadingState: PerModuleState<MenuItemActionState>
    setMenuItemLoadingState: React.Dispatch<
      React.SetStateAction<PerModuleState<MenuItemActionState>>
    >
    moduleCursorState: ModuleCursorState
    setModuleCursorState: React.Dispatch<React.SetStateAction<ModuleCursorState>>
    modulesArePaginated: boolean
    pageSize: number
  },
)

export const ContextModuleProvider = ({
  children,
  courseId,
  isMasterCourse,
  isChildCourse,
  permissions,
  NEW_QUIZZES_BY_DEFAULT,
  DEFAULT_POST_TO_SIS,
  teacherViewEnabled,
  studentViewEnabled,
  restrictQuantitativeData,
  isObserver,
  observedStudent,
  moduleMenuModalTools,
  moduleGroupMenuTools,
  moduleMenuTools,
  moduleIndexMenuModalTools,
  modulesArePaginated,
  pageSize,
}: {
  children: React.ReactNode
  courseId: string
  isMasterCourse: boolean
  isChildCourse: boolean
  permissions:
    | {
        readAsAdmin: boolean
        canAdd: boolean
        canEdit: boolean
        canDelete: boolean
        canViewUnpublished: boolean
        canDirectShare: boolean
      }
    | undefined
  NEW_QUIZZES_BY_DEFAULT: boolean | undefined
  DEFAULT_POST_TO_SIS: boolean | undefined
  teacherViewEnabled: boolean
  studentViewEnabled: boolean
  restrictQuantitativeData: boolean | undefined
  isObserver?: boolean
  observedStudent?: {id: string; name: string} | null
  moduleMenuModalTools: ExternalTool[]
  moduleGroupMenuTools: ExternalTool[]
  moduleMenuTools: ExternalTool[]
  moduleIndexMenuModalTools: ExternalTool[]
  modulesArePaginated?: boolean
  pageSize?: number
}) => {
  const [menuItemLoadingState, setMenuItemLoadingState] = useState<
    PerModuleState<MenuItemActionState>
  >({})
  const [moduleCursorState, setModuleCursorState] = useState<ModuleCursorState>({})

  return (
    <ContextModule.Provider
      value={{
        courseId,
        isMasterCourse,
        isChildCourse,
        permissions: permissions ?? {},
        NEW_QUIZZES_BY_DEFAULT: NEW_QUIZZES_BY_DEFAULT ?? false,
        DEFAULT_POST_TO_SIS: DEFAULT_POST_TO_SIS ?? false,
        teacherViewEnabled,
        studentViewEnabled,
        restrictQuantitativeData: restrictQuantitativeData ?? false,
        isObserver: isObserver ?? false,
        observedStudent: observedStudent ?? null,
        externalTools: moduleMenuModalTools,
        moduleMenuModalTools,
        moduleGroupMenuTools,
        moduleMenuTools,
        moduleIndexMenuModalTools,
        menuItemLoadingState,
        setMenuItemLoadingState,
        moduleCursorState,
        setModuleCursorState,
        modulesArePaginated: modulesArePaginated ?? false,
        pageSize: pageSize ?? 10,
      }}
    >
      {children}
    </ContextModule.Provider>
  )
}

export function useContextModule() {
  return useContext(ContextModule)
}

export const contextModuleDefaultProps = {
  courseId: '',
  isMasterCourse: false,
  isChildCourse: false,
  permissions: {
    canAdd: true,
    canEdit: true,
    canDelete: true,
    canViewUnpublished: true,
    canDirectShare: true,
    readAsAdmin: true,
    canManageSpeedGrader: true,
  },
  NEW_QUIZZES_BY_DEFAULT: false,
  DEFAULT_POST_TO_SIS: false,
  teacherViewEnabled: false,
  studentViewEnabled: false,
  restrictQuantitativeData: false,
  isObserver: false,
  observedStudent: null,
  externalTools: [],
  moduleMenuModalTools: [],
  moduleGroupMenuTools: [],
  moduleMenuTools: [],
  moduleIndexMenuModalTools: [],
  menuItemLoadingState: {},
  setMenuItemLoadingState: () => {},
  moduleCursorState: {},
  setModuleCursorState: () => {},
  modulesArePaginated: false,
  pageSize: 10,
}
