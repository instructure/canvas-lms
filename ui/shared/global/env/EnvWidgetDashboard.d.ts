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
  }
  OBSERVED_USERS_LIST: Array<{id: string; name: string; avatar_url?: string | null}>
  CAN_ADD_OBSERVEE: boolean
  SHARED_COURSE_DATA: Array<{
    courseId: string
    courseCode: string
    courseName: string
    currentGrade: number | null
    gradingScheme: 'percentage' | Array<[string, number]>
    lastUpdated: string
  }>
  OBSERVED_USER_ID: string | null
  DASHBOARD_FEATURES: {
    widget_dashboard_customization?: boolean
    platform_ui_unified_widgets_dashboard?: boolean
  }
}
