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

import React, {createContext, useContext, useState, useCallback} from 'react'

interface WidgetDashboardEditContextType {
  isEditMode: boolean
  isDirty: boolean
  enterEditMode: () => void
  exitEditMode: () => void
  saveChanges: () => void
  markDirty: () => void
}

const WidgetDashboardEditContext = createContext<WidgetDashboardEditContextType | null>(null)

export const WidgetDashboardEditProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const [isEditMode, setIsEditMode] = useState(false)
  const [isDirty, setIsDirty] = useState(false)

  const enterEditMode = useCallback(() => {
    setIsEditMode(true)
    setIsDirty(false)
  }, [])

  const exitEditMode = useCallback(() => {
    setIsEditMode(false)
    setIsDirty(false)
  }, [])

  const saveChanges = useCallback(() => {
    setIsEditMode(false)
    setIsDirty(false)
  }, [])

  const markDirty = useCallback(() => {
    setIsDirty(true)
  }, [])

  const value = {
    isEditMode,
    isDirty,
    enterEditMode,
    exitEditMode,
    saveChanges,
    markDirty,
  }

  return (
    <WidgetDashboardEditContext.Provider value={value}>
      {children}
    </WidgetDashboardEditContext.Provider>
  )
}

export function useWidgetDashboardEdit() {
  const context = useContext(WidgetDashboardEditContext)
  if (!context) {
    throw new Error('useWidgetDashboardEdit must be used within WidgetDashboardEditProvider')
  }
  return context
}
