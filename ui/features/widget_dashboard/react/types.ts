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

import React from 'react'
import {TAB_IDS} from './constants'

export type TabId = (typeof TAB_IDS)[keyof typeof TAB_IDS]

export interface DashboardTab {
  id: TabId
  label: string
}

export interface WidgetPosition {
  col: number
  row: number
}

export interface WidgetSize {
  width: number
  height: number
}

export interface Widget {
  id: string
  type: string
  position: WidgetPosition
  size: WidgetSize
  title: string
}

export interface WidgetConfig {
  columns: number
  widgets: Widget[]
}

export interface CourseWorkSummary {
  due: number
  missing: number
  submitted: number
}

export interface CourseOption {
  id: string
  name: string
}

export interface DateRangeOption {
  id: string
  label: string
  startDate: Date
  endDate: Date
}

export interface BaseWidgetProps {
  widget: Widget
  isLoading?: boolean
  error?: string | null
  onRetry?: () => void
}

export interface WidgetRenderer {
  component: React.ComponentType<BaseWidgetProps>
  displayName: string
  description: string
}

export type WidgetRegistry = Record<string, WidgetRenderer>
