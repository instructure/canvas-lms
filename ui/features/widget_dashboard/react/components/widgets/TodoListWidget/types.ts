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

export type PlannableType =
  | 'assignment'
  | 'quiz'
  | 'discussion_topic'
  | 'announcement'
  | 'wiki_page'
  | 'calendar_event'
  | 'planner_note'
  | 'assessment_request'
  | 'discussion_topic_checkpoint'

export interface PlannerOverride {
  id: number
  plannable_type: string
  plannable_id: string
  user_id: number
  workflow_state: string
  marked_complete: boolean
  dismissed: boolean
  deleted_at: string | null
  created_at: string
  updated_at: string
}

export interface SubmissionStatus {
  submitted: boolean
  excused: boolean
  graded: boolean
  late: boolean
  missing: boolean
  needs_grading: boolean
  has_feedback: boolean
  redo_request: boolean
}

export interface Plannable {
  id: string
  title: string
  course_id?: string
  todo_date?: string
  due_at?: string
  points_possible?: number
  details?: string
  unread_count?: number
  read_state?: string
  created_at: string
  updated_at: string
  assignment_id?: string
  location_name?: string
  url?: string
  all_day?: boolean
  start_at?: string
  end_at?: string
  user_id?: number
  workflow_state?: string
  sub_assignment_tag?: string
  restrict_quantitative_data?: boolean
}

export interface PlannerItem {
  plannable_id: string
  plannable_type: PlannableType
  plannable: Plannable
  plannable_date: string
  submissions?: SubmissionStatus | false
  planner_override: PlannerOverride | null
  new_activity: boolean
  context_type?: string
  context_name?: string
  context_image?: string
  course_id?: string
  html_url?: string
  details?: {
    reply_to_entry_required_count?: number
  }
}
