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

export type contentTypes =
  | 'assignments'
  | 'quizzes'
  | 'discussions'
  | 'groups'
  | 'collaborations'
  | 'outcomes'

export type errorTypes =
  | 'peer_reviews'
  | 'submission_types'
  | 'groups'
  | 'group_category'
  | 'discussion_type'
  | 'quiz_type'
  | 'rubric'
  | 'workflow_state'

export type CanvasCareerValidationResponse = {
  errors: ValidationErrors
}

export type ValidationErrors = {
  [k in contentTypes]?: ContentError[]
}

export type ContentError = {
  id: number
  name: string
  link?: string
  errors: {
    [k in errorTypes]?: {
      attribute: string
      type: string
      message: string
    }
  }
}

export type CompletionProgressResponse = {
  id: number
  context_id: number
  context_type: string
  user_id: number
  tag: string
  completion: number
  workflow_state: ProgressWorkflowState
  created_at: string
  updated_at: string
  message: string | null
  url: string
  success?: true
  errors?: string
}

export type ProgressWorkflowState = 'queued' | 'running' | 'completed' | 'failed'
