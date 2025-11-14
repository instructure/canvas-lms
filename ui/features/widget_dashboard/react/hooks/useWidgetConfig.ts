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

import {useState, useCallback, useEffect} from 'react'
import {useMutation} from '@tanstack/react-query'
import {UPDATE_WIDGET_DASHBOARD_CONFIG} from '../constants'
import {executeQuery} from '@canvas/graphql'
import {useWidgetDashboard} from './useWidgetDashboardContext'

interface UpdateDashboardConfigResponse {
  updateWidgetDashboardConfig?: {
    widgetId: string
    filters: Record<string, unknown>
    errors?: Array<{message: string}>
  }
}

/**
 * Generic hook for managing widget-specific configuration that persists to the backend.
 * Currently stores config under widget_dashboard_config.filters[widgetId].
 * This will be extended in the future to support widget positioning and other config types.
 *
 * @param widgetId - Unique identifier for the widget
 * @param configKey - The key within the widget's config object (e.g., 'selectedCourse', 'selectedDateFilter')
 * @param defaultValue - Default value if no persisted value exists
 * @returns Tuple of [currentValue, setValue] similar to useState
 */
export function useWidgetConfig<T>(
  widgetId: string,
  configKey: string,
  defaultValue: T,
): [T, (value: T) => void] {
  const {widgetConfig, updateWidgetConfig, observedUserId} = useWidgetDashboard()

  const transformFromBackend = useCallback(
    (value: unknown): T => {
      const isCourseWorkWidget = [
        'course-work-widget',
        'course-work-combined-widget',
        'course-work-summary-widget',
      ].includes(widgetId)

      if (
        isCourseWorkWidget &&
        configKey === 'selectedCourse' &&
        typeof value === 'string' &&
        value.startsWith('course_') &&
        value !== 'all'
      ) {
        return value.replace('course_', '') as T
      }

      return value as T
    },
    [widgetId, configKey],
  )

  const [configValue, setConfigValue] = useState<T>(() => {
    const initialConfig = widgetConfig[widgetId]
    if (initialConfig && configKey in initialConfig) {
      return transformFromBackend(initialConfig[configKey])
    }
    return defaultValue
  })

  useEffect(() => {
    const initialConfig = widgetConfig[widgetId]
    if (initialConfig && configKey in initialConfig) {
      setConfigValue(transformFromBackend(initialConfig[configKey]))
    }
  }, [widgetConfig, widgetId, configKey, transformFromBackend])

  const updateConfigMutation = useMutation({
    mutationFn: async (newConfig: Record<string, unknown>) => {
      // Ensure we always pass a plain object, never null/undefined
      const filters = newConfig && typeof newConfig === 'object' ? newConfig : {}

      const result = await executeQuery<UpdateDashboardConfigResponse>(
        UPDATE_WIDGET_DASHBOARD_CONFIG,
        {
          widgetId,
          filters,
        },
      )
      return result
    },
    onError: error => {
      console.error('Failed to save widget config preference:', error)
    },
  })

  const handleConfigChange = useCallback(
    (newValue: T) => {
      setConfigValue(newValue)

      const existingConfig = widgetConfig[widgetId] || {}
      let transformedValue = newValue

      const isCourseWorkWidget = [
        'course-work-widget',
        'course-work-combined-widget',
        'course-work-summary-widget',
      ].includes(widgetId)

      if (isCourseWorkWidget && configKey === 'selectedCourse' && typeof newValue === 'string') {
        transformedValue = (
          newValue === 'all' || newValue.startsWith('course_') ? newValue : `course_${newValue}`
        ) as T
      }

      const updatedConfig: Record<string, unknown> = {
        ...existingConfig,
        [configKey]: transformedValue,
      }

      if (
        isCourseWorkWidget &&
        'selectedCourse' in updatedConfig &&
        typeof updatedConfig.selectedCourse === 'string'
      ) {
        const courseValue = updatedConfig.selectedCourse
        if (courseValue !== 'all' && !courseValue.startsWith('course_')) {
          updatedConfig.selectedCourse = `course_${courseValue}`
        }
      }

      updateWidgetConfig(widgetId, updatedConfig)

      if (!observedUserId) {
        updateConfigMutation.mutate(updatedConfig)
      }
    },
    [configKey, widgetConfig, widgetId, updateWidgetConfig, updateConfigMutation, observedUserId],
  )

  return [configValue, handleConfigChange]
}
