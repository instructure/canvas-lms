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
  relative: number
}

export interface WidgetSize {
  width: number
  height: number
}

export interface Widget {
  id: string
  type: string
  position: WidgetPosition
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
  isEditMode?: boolean
  dragHandleProps?: any
}

export interface WidgetRenderer {
  component: React.ComponentType<BaseWidgetProps>
  displayName: string
  description: string
}

export type WidgetRegistry = Record<string, WidgetRenderer>

export type GradingStandardData = Array<[string, number]>

export interface CourseGrade {
  courseId: string
  courseCode: string
  courseName: string
  currentGrade: number | null
  gradingScheme: 'percentage' | GradingStandardData
  lastUpdated?: Date | null
}

export interface CourseGradeCardProps {
  courseId: string
  courseCode: string
  courseName: string
  currentGrade: number | null
  gradingScheme: 'percentage' | GradingStandardData
  lastUpdated?: Date | null
  onShowGradebook: () => void
  gridIndex?: number
  globalGradeVisibility?: boolean
  onGradeVisibilityChange?: (visible: boolean) => void
}
export interface Announcement {
  id: string
  title: string
  message: string
  posted_at: string
  html_url: string
  context_code: string
  course?: {
    id: string
    name: string
    courseCode?: string
  }
  author?: {
    _id: string
    name: string
    avatarUrl: string
  } | null
  isRead?: boolean
}

export interface RecentGradeSubmission {
  _id: string
  submittedAt: string | null
  gradedAt: string | null
  score: number | null
  grade: string | null
  state: string
  assignment: {
    _id: string
    name: string
    htmlUrl: string
    pointsPossible: number | null
    submissionTypes: string[]
    quiz: {_id: string; title: string} | null
    discussion: {_id: string; title: string} | null
    course: {
      _id: string
      name: string
      courseCode?: string
    }
  }
}

export interface GradeItemProps {
  submission: RecentGradeSubmission
}

export interface ConversationParticipant {
  id: string
  name: string
  avatarUrl?: string
}

export interface InboxMessage {
  id: string
  subject: string
  lastMessageAt: string
  messagePreview: string
  workflowState: 'read' | 'unread' | 'archived'
  conversationUrl: string
  participants: ConversationParticipant[]
}
