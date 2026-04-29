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

export type LoadState = 'not_loaded' | 'loading' | 'loaded'

export type MigrationState =
  | 'queued'
  | 'exporting'
  | 'exports_failed'
  | 'exported'
  | 'importing'
  | 'imports_failed'
  | 'completed'
  | 'deleted'

export interface Term {
  id: string
  name: string
}

export interface Account {
  id: string
  name: string
}

export interface Teacher {
  display_name: string
}

export interface Course {
  id: string
  name: string
  course_code: string
  term: Term
  teachers: Teacher[]
  teacher_count?: string
  sis_course_id?: string
}

export interface CourseInfo {
  id: string
  name: string
  enrollment_term_id: string
  sis_course_id?: string
}

export type LockableAttribute =
  | 'points'
  | 'content'
  | 'due_dates'
  | 'availability_dates'
  | 'settings'
  | 'deleted'

export interface MigrationException {
  course_id: string
  conflicting_changes?: LockableAttribute[]
}

export type AssetType =
  | 'assignment'
  | 'quiz'
  | 'discussion_topic'
  | 'wiki_page'
  | 'attachment'
  | 'context_module'
  | 'learning_outcome'
  | 'learning_outcome_group'
  | 'announcement'
  | 'rubric'
  | 'syllabus'
  | 'media_tracks'

export type ChangeType = 'created' | 'updated' | 'deleted'

export interface MigrationChange {
  asset_id: string
  asset_type: AssetType
  asset_name: string
  change_type: ChangeType
  html_url?: string
  exceptions?: MigrationException[]
  locked?: boolean
}

export interface Migration {
  id: string
  workflow_state: MigrationState
  comment?: string
  created_at: string
  exports_started_at?: string
  imports_queued_at?: string
  imports_completed_at?: string
  changes?: MigrationChange[]
}

export interface UnsyncedChange {
  asset_id: string
  asset_type: string
  asset_name: string
  change_type: string
  html_url: string
  locked: boolean
}

export interface Notification {
  id: string
  message: string
  err?: Error
}

export interface ItemLocks {
  content?: boolean
  points?: boolean
  due_dates?: boolean
  availability_dates?: boolean
}

export interface ItemLocksByObject {
  assignment?: ItemLocks
  discussion_topic?: ItemLocks
  wiki_page?: ItemLocks
  quiz?: ItemLocks
  attachment?: ItemLocks
}

export interface ChangeLogEntry {
  changeId: string | null
  status: LoadState
  data: Migration | null
}

export interface BlueprintState {
  course: CourseInfo
  masterCourse: CourseInfo
  isMasterCourse: boolean
  isChildCourse: boolean
  canManageCourse: boolean
  canAutoPublishCourses: boolean
  accountId: string
  terms: Term[]
  subAccounts: Account[]
  itemNotificationFeatureEnabled: boolean
  notifications: Notification[]
  changeLogs: Record<string, ChangeLogEntry>
  selectedChangeLog: string | null
}

export interface RouteParams {
  blueprintId: string
  changeId: string
}
