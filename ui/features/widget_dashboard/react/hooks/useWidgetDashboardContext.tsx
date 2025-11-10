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

import {createContext, useContext, useMemo} from 'react'

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
}

export interface SharedCourseData {
  courseId: string
  courseCode: string
  courseName: string
  currentGrade: number | null
  gradingScheme: 'percentage' | Array<[string, number]>
  lastUpdated: string
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
  const contextValue = useMemo(
    () => ({
      preferences: preferences ?? widgetDashboardDefaultProps.preferences,
      observedUsersList: observedUsersList ?? widgetDashboardDefaultProps.observedUsersList,
      canAddObservee: canAddObservee ?? widgetDashboardDefaultProps.canAddObservee,
      currentUser: currentUser ?? widgetDashboardDefaultProps.currentUser,
      observedUserId: observedUserId ?? widgetDashboardDefaultProps.observedUserId,
      currentUserRoles: currentUserRoles ?? widgetDashboardDefaultProps.currentUserRoles,
      sharedCourseData: sharedCourseData ?? widgetDashboardDefaultProps.sharedCourseData,
      dashboardFeatures: dashboardFeatures ?? widgetDashboardDefaultProps.dashboardFeatures,
    }),
    [
      preferences,
      observedUsersList,
      canAddObservee,
      currentUser,
      observedUserId,
      currentUserRoles,
      sharedCourseData,
      dashboardFeatures,
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
  },
  observedUsersList: [],
  canAddObservee: false,
  currentUser: null,
  observedUserId: null,
  currentUserRoles: [],
  sharedCourseData: [],
  dashboardFeatures: {},
}
