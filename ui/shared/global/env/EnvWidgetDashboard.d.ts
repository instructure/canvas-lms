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

export interface EnvWidgetDashboard {
  PREFERENCES: {
    dashboard_view: string
    hide_dashcard_color_overlays: boolean
    custom_colors: Record<string, string>
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
  OBSERVED_USERS_LIST: Array<{id: string; name: string; avatar_url?: string | null}>
  CAN_ADD_OBSERVEE: boolean
  SHARED_COURSE_DATA: Array<{
    courseId: string
    courseCode: string
    courseName: string
    originalName?: string
    currentGrade: number | null
    gradingScheme: 'percentage' | Array<[string, number]>
    lastUpdated: string
  }>
  OBSERVED_USER_ID: string | null
  DASHBOARD_FEATURES: {
    platform_ui_unified_widgets_dashboard?: boolean
    widget_dashboard_dark_mode?: boolean
    educator_dashboard?: boolean
  }
  WIDGET_DASHBOARD_DARK_MODE?: boolean
}
