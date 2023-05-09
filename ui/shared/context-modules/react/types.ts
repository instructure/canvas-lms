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

export type CanvasId = string | number

export interface CanvasProgressAPIResult {
  json: CanvasProgress
}

export interface CanvasProgress {
  id: string
  workflow_state: 'queued' | 'running' | 'failed' | 'completed'
  message: string | null
  completion: number | null
}

export interface ModuleItemAttributes {
  module_item_id: number
}

export interface ModuleItemModel {
  attributes: ModuleItemAttributes
  get: (name: string) => any
}

export interface ModuleItemView {
  model: ModuleItemModel
}

export interface ModuleItem {
  model: ModuleItemModel
  view: ModuleItemView
}

export interface KeyedModuleItems {
  [key: string]: ModuleItem[]
}

export interface ModuleItemStateData {
  published?: boolean
  bulkPublishInFlight?: boolean
}

export interface FetchedModule {
  id: string
  items_count: number
  items_url: string
  name: string
  position: number
  prerequisite_module_ids: number[]
  publish_final_grade: boolean
  publish_warning: boolean
  published: boolean
  require_sequential_progress: true
  unlock_at: string | null
}
export interface FetchedModuleItem {
  id: string
  published: boolean
  type: string
  content_id?: string
  page_url?: string
  html_url?: string
}
export interface FetchedModuleWithItems extends FetchedModule {
  items: FetchedModuleItem[]
}

export interface OneFetchLinkHeader {
  page: string
  per_page: string
  rel: string
  url: string
}

export interface FetchLinkHeader {
  current: OneFetchLinkHeader
  first: OneFetchLinkHeader
  last: OneFetchLinkHeader
  next: OneFetchLinkHeader
}

export interface DoFetchModuleItemsResponse {
  json: FetchedModuleItem[]
  link: FetchLinkHeader
}

export interface DoFetchModuleResponse {
  json: FetchedModule
}

export interface DoFetchModuleWithItemsResponse {
  json: FetchedModuleWithItems[]
  link: FetchLinkHeader
}
