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

import {createContext, useContext, useMemo, useState, useCallback} from 'react'

interface ObservedUser {
  id: string
  name: string
  avatar_url?: string | null
}

interface CurrentUser {
  id: string
  display_name: string
  avatar_image_url: string
}

interface DashboardPreferences {
  dashboard_view: string
  hide_dashcard_color_overlays: boolean
  custom_colors: Record<string, string>
  learner_dashboard_tab_selection?: 'dashboard' | 'courses'
  widget_dashboard_config?: {
    filters?: Record<string, Record<string, unknown>>
    layout?: {
      columns: number
      widgets: Array<{
        id: string
        type: string
        position: {col: number; row: number; relative: number}
        title: string
      }>
    }
  }
}

export interface SharedCourseData {
  courseId: string
  courseCode: string
  courseName: string
  originalName?: string
  currentGrade: number | null
  gradingScheme: 'percentage' | Array<[string, number]>
  lastUpdated: string
  courseColor?: string
  term?: string | null
  image?: string
}

interface DashboardFeatures {
  widget_dashboard_customization?: boolean
}

const WidgetDashboardContext = createContext<{
  preferences: DashboardPreferences
  observedUsersList: ObservedUser[]
  canAddObservee: boolean
  currentUser: CurrentUser | null
  observedUserId: string | null
  currentUserRoles: string[]
  sharedCourseData: SharedCourseData[]
  dashboardFeatures: DashboardFeatures
  widgetConfig: Record<string, Record<string, unknown>>
  updateWidgetConfig: (widgetId: string, config: Record<string, unknown>) => void
  updateCourseColor: (courseId: string, color: string) => void
  updateCourseNickname: (courseId: string, nickname: string) => void
}>({
  preferences: {
    dashboard_view: 'cards',
    hide_dashcard_color_overlays: false,
    custom_colors: {},
  },
  observedUsersList: [],
  canAddObservee: false,
  currentUser: null,
  observedUserId: null,
  currentUserRoles: [],
  sharedCourseData: [],
  dashboardFeatures: {},
  widgetConfig: {},
  updateWidgetConfig: () => {},
  updateCourseColor: () => {},
  updateCourseNickname: () => {},
})

export const WidgetDashboardProvider = ({
  children,
  preferences,
  observedUsersList,
  canAddObservee,
  currentUser,
  observedUserId,
  currentUserRoles,
  sharedCourseData,
  dashboardFeatures,
}: {
  children: React.ReactNode
  preferences?: DashboardPreferences
  observedUsersList?: ObservedUser[]
  canAddObservee?: boolean
  currentUser?: CurrentUser | null
  observedUserId?: string | null
  currentUserRoles?: string[]
  sharedCourseData?: SharedCourseData[]
  dashboardFeatures?: DashboardFeatures
}) => {
  const [widgetConfig, setWidgetConfig] = useState<Record<string, Record<string, unknown>>>(() => {
    const initialPrefs = preferences ?? widgetDashboardDefaultProps.preferences
    return initialPrefs.widget_dashboard_config?.filters ?? {}
  })

  const updateWidgetConfig = useCallback((widgetId: string, config: Record<string, unknown>) => {
    setWidgetConfig(prev => ({
      ...prev,
      [widgetId]: config,
    }))
  }, [])

  const [courseColorOverrides, setCourseColorOverrides] = useState<Record<string, string>>({})
  const [courseNicknameOverrides, setCourseNicknameOverrides] = useState<Record<string, string>>({})

  const updateCourseColor = useCallback((courseId: string, color: string) => {
    setCourseColorOverrides(prev => ({
      ...prev,
      [courseId]: color,
    }))
  }, [])

  const updateCourseNickname = useCallback((courseId: string, nickname: string) => {
    setCourseNicknameOverrides(prev => ({
      ...prev,
      [courseId]: nickname,
    }))
  }, [])

  const mergedCourseData = useMemo(() => {
    const baseData = sharedCourseData ?? widgetDashboardDefaultProps.sharedCourseData
    return baseData.map(course => {
      const nicknameOverride = courseNicknameOverrides[course.courseId]
      return {
        ...course,
        courseColor: courseColorOverrides[course.courseId] ?? course.courseColor,
        courseName: nicknameOverride ?? course.courseName,
      }
    })
  }, [sharedCourseData, courseColorOverrides, courseNicknameOverrides])

  const contextValue = useMemo(
    () => ({
      preferences: preferences ?? widgetDashboardDefaultProps.preferences,
      observedUsersList: observedUsersList ?? widgetDashboardDefaultProps.observedUsersList,
      canAddObservee: canAddObservee ?? widgetDashboardDefaultProps.canAddObservee,
      currentUser: currentUser ?? widgetDashboardDefaultProps.currentUser,
      observedUserId: observedUserId ?? widgetDashboardDefaultProps.observedUserId,
      currentUserRoles: currentUserRoles ?? widgetDashboardDefaultProps.currentUserRoles,
      sharedCourseData: mergedCourseData,
      dashboardFeatures: dashboardFeatures ?? widgetDashboardDefaultProps.dashboardFeatures,
      widgetConfig,
      updateWidgetConfig,
      updateCourseColor,
      updateCourseNickname,
    }),
    [
      preferences,
      observedUsersList,
      canAddObservee,
      currentUser,
      observedUserId,
      currentUserRoles,
      mergedCourseData,
      dashboardFeatures,
      widgetConfig,
      updateWidgetConfig,
      updateCourseColor,
      updateCourseNickname,
    ],
  )

  return (
    <WidgetDashboardContext.Provider value={contextValue}>
      {children}
    </WidgetDashboardContext.Provider>
  )
}

export function useWidgetDashboard() {
  return useContext(WidgetDashboardContext)
}

export const widgetDashboardDefaultProps = {
  preferences: {
    dashboard_view: 'cards',
    hide_dashcard_color_overlays: false,
    custom_colors: {},
    learner_dashboard_tab_selection: 'dashboard' as const,
    widget_dashboard_config: {
      filters: {},
    },
  },
  observedUsersList: [],
  canAddObservee: false,
  currentUser: null,
  observedUserId: null,
  currentUserRoles: [],
  sharedCourseData: [],
  dashboardFeatures: {},
}
