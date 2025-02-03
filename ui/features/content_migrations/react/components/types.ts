/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  type AdjustDates,
  type DaySub,
  type DateShifts,
  type DateShiftsCommon,
  type DateAdjustmentConfig,
  type MigrationCreateRequestBody,
  type onSubmitMigrationFormCallback,
  type ItemType,
} from '@canvas/content-migrations'

export type ContentMigrationItemSettings = {
  source_course_id: string
  source_course_name: string
  source_course_html_url: string
}

export type Migrator = {
  type: string
  requires_file_upload: true
  name: string
  required_settings: string
}

export type ContentMigrationItemAttachment = {
  display_name: string
  url: string
}

export type ProgressWorkflowState = 'queued' | 'running' | 'completed' | 'failed'

export type StatusPillState = ProgressWorkflowState | 'waiting_for_select'

export type ContentMigrationWorkflowState =
  | 'pre_processing'
  | 'pre_processed'
  | 'queued'
  | 'failed'
  | 'waiting_for_select'
  | 'running'
  | 'completed'

export type ContentMigrationItem = {
  id: string
  migration_type: string
  migration_type_title: string
  progress_url: string
  settings: ContentMigrationItemSettings
  attachment?: ContentMigrationItemAttachment
  completion?: number
  workflow_state: ContentMigrationWorkflowState
  migration_issues_count: number
  migration_issues_url: string
  created_at: string
}

export type AttachmentProgressResponse = ContentMigrationItem & {
  type: string
  total: number
  timeStamp: number
  loaded: number
}

export type UpdateMigrationItemType = (
  contentMigrationItemId: string,
  data?: object,
  noXHR?: boolean,
) => Promise<ContentMigrationItem | undefined>

export type QuestionBankSettings = {
  question_bank_id?: string | number
  question_bank_name?: string
}

export type GenericItemResponse = {
  property: string
  title: string
  type: ItemType
  sub_items?: GenericItemResponse[]
  sub_items_url?: string
  submodule_count?: number // this only exist for modules
  linked_resource?: {
    migration_id: string
    type: ItemType
  }
  migration_id?: string
}

export type SelectiveDataRequest = {
  id: string
  user_id: string
  copy: {[key: string]: string | {[key: string]: string}}
  workflow_state: ContentMigrationWorkflowState
}

export type {
  AdjustDates,
  DaySub,
  DateShifts,
  DateShiftsCommon,
  DateAdjustmentConfig,
  MigrationCreateRequestBody,
  onSubmitMigrationFormCallback,
}
