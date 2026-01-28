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

export interface LLMConversationMessage {
  role: 'User' | 'Assistant'
  text: string
  timestamp?: Date
}

export interface ConversationProgress {
  current: number
  total: number
  percentage: number
  objectives: Array<{
    objective: string
    status: '' | 'covered'
  }>
}

export interface LLMConversationViewProps {
  isOpen: boolean
  onClose: () => void
  returnFocusRef?: React.RefObject<HTMLElement>
  courseId?: string | number
  aiExperienceId?: string
  aiExperienceTitle?: string
  facts?: string
  learningObjectives?: string
  scenario?: string
  isExpanded?: boolean
  onToggleExpanded?: () => void
  isTeacherPreview?: boolean
}
