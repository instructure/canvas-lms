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

export interface AIExperience {
  id: string
  course_id: string | number
  title: string
  description?: string
  facts?: string
  learning_objective?: string
  pedagogical_guidance?: string
  can_manage: boolean
}

export interface StudentConversation {
  id: string | null
  user_id: string
  llm_conversation_id?: string
  workflow_state?: 'active' | 'completed' | 'deleted'
  created_at?: string
  updated_at?: string
  has_conversation?: boolean
  student: {
    id: string
    name: string
    avatar_url?: string
  }
}

export interface ConversationMessage {
  id?: string
  role: 'user' | 'assistant' | 'User' | 'Assistant'
  content?: string
  text?: string
  timestamp?: string
  feedback?: Array<{
    id: string
    user_id: string
    vote: 'liked' | 'disliked'
    feedback_message: string | null
    created_at: string
    updated_at: string
  }>
}

export interface ConversationDetail extends StudentConversation {
  messages: ConversationMessage[]
  progress?: {
    current: number
    total: number
    percentage: number
    objectives: Array<{objective: string; status: '' | 'covered'}>
  }
}

export interface FeedbackItem {
  id: string
  user_id: string
  vote: 'liked' | 'disliked'
  feedback_message: string | null
  created_at: string
  updated_at: string
}

export interface LLMConversationMessage {
  id?: string
  role: 'User' | 'Assistant'
  text: string
  timestamp?: Date
  feedback?: FeedbackItem[]
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
  returnFocusRef?: React.MutableRefObject<HTMLElement | null>
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
