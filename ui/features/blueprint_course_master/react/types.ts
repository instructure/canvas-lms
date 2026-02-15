/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export interface Teacher {
  display_name: string
}

export interface Term {
  id: string
  name: string
}

export interface Account {
  id: string
  name: string
}

export interface Course {
  id: string | null
  name: string
  original_name?: string
  course_code: string
  term: Term
  teachers?: Teacher[]
  teacher_count?: string
  sis_course_id?: string
  concluded?: boolean
}

export type MigrationState =
  | 'void'
  | 'unknown'
  | 'queued'
  | 'exporting'
  | 'imports_queued'
  | 'completed'
  | 'exports_failed'
  | 'imports_failed'

export type MigrationChangeType = 'created' | 'updated' | 'deleted' | 'initial_sync'

export type MigrationAssetType =
  | 'announcement'
  | 'assessment_question_bank'
  | 'assignment'
  | 'assignment_group'
  | 'attachment'
  | 'calendar_event'
  | 'context_external_tool'
  | 'context_module'
  | 'course_pace'
  | 'discussion_topic'
  | 'folder'
  | 'learning_outcome'
  | 'learning_outcome_group'
  | 'media_track'
  | 'quiz'
  | 'rubric'
  | 'settings'
  | 'sub_assignment'
  | 'syllabus'
  | 'wiki_page'

export interface MigrationException {
  course_id: string
  conflicting_changes?: string[]
  name?: string
  term?: Term
}

export interface MigrationChange {
  asset_id: string
  asset_type: MigrationAssetType | string
  asset_name: string
  change_type: MigrationChangeType
  html_url?: string
  locale?: string
  exceptions?: MigrationException[]
}

export interface Migration {
  id: string
  workflow_state: MigrationState
  comment?: string
  created_at: string
  exports_started_at?: string
  imports_queued_at?: string
  imports_completed_at?: string
  changes: MigrationChange[]
}

export interface UnsyncedChange {
  asset_id: string
  asset_type: MigrationAssetType | string
  asset_name: string
  change_type: MigrationChangeType
  html_url: string
  locked: boolean
  locale?: string
}

export interface CourseFilterFilters {
  isActive: boolean
  search: string
  term: string
  subAccount: string
}
