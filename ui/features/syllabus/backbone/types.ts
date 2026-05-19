/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

export type SyllabusEventType =
  | 'assignment'
  | 'sub_assignment'
  | 'event'
  | 'wiki_page'
  | 'discussion_topic'
  | string

export interface SyllabusOverride {
  id: number | string
  title?: string
}

export interface SyllabusEventApi {
  id: number | string
  related_id?: number | string
  type?: SyllabusEventType
  title?: string
  html_url?: string
  start_at?: string
  end_at?: string
  todo_at?: string
  hidden?: boolean
  parent_event_id?: number | string
  workflow_state?: string
  submission_types?: string
  assignment_overrides?: SyllabusOverride[]
  sub_assignment_overrides?: SyllabusOverride[]
  sub_assignment?: {
    sub_assignment_tag?: string
  }
}

export interface SyllabusFetchData extends Record<string, unknown> {
  context_codes?: string[]
  scope?: string
  type?: string
  all_events?: string
  include_past_appointments?: string
  excludes?: string[]
  per_page?: number
  filter?: string
}

export interface SyllabusFetchOptions extends Record<string, unknown> {
  data?: SyllabusFetchData
  error?: (...args: unknown[]) => unknown
  page?: string
  remove?: boolean
  success?: (...args: unknown[]) => unknown
}

export interface SyllabusModelLike {
  get(attribute: string): unknown
}

export interface SyllabusCollectionLike {
  models: SyllabusModelLike[]
  on(eventName: string, callback: (...args: unknown[]) => unknown): unknown
}
