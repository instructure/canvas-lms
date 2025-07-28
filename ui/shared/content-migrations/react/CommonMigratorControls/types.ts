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

export type AdjustDates = {
  enabled: boolean
  operation: 'shift_dates' | 'remove_dates'
}

export type DaySub = {
  to: number
  from: number
  id: number
}

export type DateShiftsCommon = {
  old_start_date?: string
  new_start_date?: string
  old_end_date?: string
  new_end_date?: string
}

export type DateShifts = DateShiftsCommon & {
  day_substitutions: DaySub[]
}

export type DateAdjustmentConfig = {
  adjust_dates: AdjustDates
  date_shift_options: DateShifts
}

export type submitMigrationFormData = {
  errored?: boolean
  adjust_dates?: AdjustDates
  selective_import?: boolean
  date_shift_options?: DateShifts
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
  preAttachmentFile?: File,
) => void

export type DateShiftsRequestBody = DateShiftsCommon & {
  remove_dates?: boolean
  shift_dates?: boolean
  day_substitutions?: Record<string, string>
}

export type MigrationCreateRequestBody = {
  course_id: string
  migration_type: string
  date_shift_options: DateShiftsRequestBody
  selective_import: boolean
  settings: Record<string, any>
  pre_attachment?: {
    name: string
    no_redirect: boolean
    size: number
  }
}
