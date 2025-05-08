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

const ContextModule = createContext<{
  courseId: string
  isMasterCourse: boolean
  isChildCourse: boolean
  permissions: Record<string, boolean>
  NEW_QUIZZES_BY_DEFAULT: boolean
  DEFAULT_POST_TO_SIS: boolean
  state: Record<string, any>
  setState: (state: Record<string, any>) => void
}>(
  {} as {
    courseId: string
    isMasterCourse: boolean
    isChildCourse: boolean
    permissions: Record<string, boolean>
    NEW_QUIZZES_BY_DEFAULT: boolean
    DEFAULT_POST_TO_SIS: boolean
    state: Record<string, any>
    setState: (state: Record<string, any>) => void
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
}) => {
  const [state, setState] = useState({})

  return (
    <ContextModule.Provider
      value={{
        courseId,
        isMasterCourse,
        isChildCourse,
        permissions: permissions ?? {},
        NEW_QUIZZES_BY_DEFAULT: NEW_QUIZZES_BY_DEFAULT ?? false,
        DEFAULT_POST_TO_SIS: DEFAULT_POST_TO_SIS ?? false,
        state,
        setState,
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
  },
  NEW_QUIZZES_BY_DEFAULT: false,
  DEFAULT_POST_TO_SIS: false,
  state: {},
  setState: () => {},
}
