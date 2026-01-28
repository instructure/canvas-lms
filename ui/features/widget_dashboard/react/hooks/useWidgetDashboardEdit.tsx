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
import {useMutation} from '@tanstack/react-query'
import {executeQuery} from '@canvas/graphql'
import {useScope as createI18nScope} from '@canvas/i18n'
import {UPDATE_WIDGET_DASHBOARD_LAYOUT} from '../constants'
import type {WidgetConfig} from '../types'

const I18n = createI18nScope('widget_dashboard')

interface UpdateLayoutResponse {
  updateWidgetDashboardLayout?: {
    layout: string | null
    errors?: Array<{message: string}>
  }
}

interface WidgetDashboardEditContextType {
  isEditMode: boolean
  isDirty: boolean
  isSaving: boolean
  saveError: string | null
  enterEditMode: () => void
  exitEditMode: () => void
  saveChanges: (config: WidgetConfig) => Promise<void>
  markDirty: () => void
  clearError: () => void
}

const WidgetDashboardEditContext = createContext<WidgetDashboardEditContextType | null>(null)

export const WidgetDashboardEditProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const [isEditMode, setIsEditMode] = useState(false)
  const [isDirty, setIsDirty] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  const enterEditMode = useCallback(() => {
    setIsEditMode(true)
    setIsDirty(false)
    setSaveError(null)
  }, [])

  const exitEditMode = useCallback(() => {
    setIsEditMode(false)
    setIsDirty(false)
    setSaveError(null)
  }, [])

  const saveMutation = useMutation({
    mutationFn: async (config: WidgetConfig) => {
      const result = await executeQuery<UpdateLayoutResponse>(UPDATE_WIDGET_DASHBOARD_LAYOUT, {
        layout: JSON.stringify(config),
      })

      if (result.updateWidgetDashboardLayout?.errors?.length) {
        throw new Error(result.updateWidgetDashboardLayout.errors[0].message)
      }

      return result
    },
    onError: (error: Error) => {
      setSaveError(error.message || I18n.t('Failed to save widget layout'))
    },
  })

  const saveChanges = useCallback(
    async (config: WidgetConfig) => {
      setSaveError(null)
      try {
        await saveMutation.mutateAsync(config)
        setIsEditMode(false)
        setIsDirty(false)
      } catch {
        // Error is handled by mutation onError callback
      }
    },
    [saveMutation],
  )

  const markDirty = useCallback(() => {
    setIsDirty(true)
  }, [])

  const clearError = useCallback(() => {
    setSaveError(null)
  }, [])

  const value = {
    isEditMode,
    isDirty,
    isSaving: saveMutation.isPending,
    saveError,
    enterEditMode,
    exitEditMode,
    saveChanges,
    markDirty,
    clearError,
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
