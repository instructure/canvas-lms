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
  role: 'user' | 'assistant' | 'User' | 'Assistant'
  content?: string
  text?: string
  timestamp?: string
}

export interface ConversationDetail extends StudentConversation {
  messages: ConversationMessage[]
  progress?: {
    status: string
    [key: string]: any
  }
}

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
