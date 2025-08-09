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

export const TAB_IDS = {
  DASHBOARD: 'dashboard',
  COURSES: 'courses',
} as const

export const WIDGET_TYPES = {
  COURSE_WORK_SUMMARY: 'course_work_summary',
} as const

export const DEFAULT_WIDGET_CONFIG = {
  columns: 3,
  widgets: [
    {
      id: 'course-work-widget',
      type: WIDGET_TYPES.COURSE_WORK_SUMMARY,
      position: {col: 1, row: 1},
      size: {width: 2, height: 1},
      title: "Today's course work",
    },
  ],
}
