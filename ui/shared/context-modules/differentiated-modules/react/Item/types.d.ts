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

import {FetchLinkHeader} from '@canvas/do-fetch-api-effect/types'

export interface BaseDateDetails {
  id: string
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  only_visible_to_overrides: boolean
}

export interface StudentInfo {
  id: string
  name: string
}
export interface DateDetailsOverride {
  id?: string
  assignment_id?: number | null
  title?: string
  course_section_id?: string | null
  students?: StudentInfo[]
  student_ids?: string[]
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  all_day?: boolean
  all_day_date?: string | null
  context_module_id?: string | null
  context_module_name?: string | null
}

export interface ItemAssignToCardSpec {
  overrideId?: string
  key: string
  isValid: boolean
  hasAssignees: boolean
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
  selectedAssigneeIds: string[]
  defaultOptions?: string[]
  contextModuleId?: string | null
  contextModuleName?: string | null
}

export interface DateDetails extends BaseDateDetails {
  overrides?: DateDetailsOverride[]
}

export interface DateDetailsPayload extends BaseDateDetails {
  assignment_overrides: DateDetailsOverride[]
}

export interface FetchDueDatesResponse {
  json: DateDetails
  link?: FetchLinkHeader
}
