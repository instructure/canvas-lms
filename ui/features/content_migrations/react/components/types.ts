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

export type ContentMigrationWorkflowState =
  | 'pre_processing'
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

export type AdjustDates = {
  enabled: boolean
  operation: 'shift_dates' | 'remove_dates'
}

export type DaySub = {
  to: number
  from: number
  id: number
}

export type DateShifts = {
  substitutions: {}
  old_start_date: string | false
  new_start_date: string | false
  old_end_date: string | false
  new_end_date: string | false
  day_substitutions: DaySub[]
}

export type DateAdjustmentConfig = {
  adjust_dates: AdjustDates
  date_shift_options: DateShifts
}

export type submitMigrationFormData = {
  errored?: boolean
  adjust_dates: AdjustDates
  selective_import: boolean
  date_shift_options: DateShifts
  settings: {[key: string]: any}
  daySubCollection?: object
  pre_attachment?: {
    name: string
    size: number
    no_redirect: boolean
  }
}

export type onSubmitMigrationFormCallback = (
  formData: submitMigrationFormData,
  preAttachmentFile?: File
) => void

export type ContentMigrationResponse = ContentMigrationItem & {
  pre_attachment?: {
    file_param: string
    progress: number | null
    upload_url: string
    upload_params: {
      filename: string
      content_type: string
    }
  }
}

export type AttachmentProgressResponse = ContentMigrationItem & {
  type: string
  total: number
  timeStamp: number
  loaded: number
}
