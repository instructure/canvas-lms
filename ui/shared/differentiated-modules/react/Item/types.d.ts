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
  id: number
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
  id: number
  assignment_id: number | null
  title: string
  course_section_id: number | null
  students?: StudentInfo[]
  due_at: string
  unlock_at: string | null
  lock_at: string | null
  all_day: boolean
  all_day_date: string | null
}

export interface DateDetails extends BaseDateDetails {
  overrides?: DateDetailsOverride[]
}

export interface FetchDueDatesResponse {
  json: DateDetails
  link?: FetchLinkHeader
}
