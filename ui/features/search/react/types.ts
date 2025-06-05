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

import {Assignment} from 'api'

export type Result = {
  content_id: string
  content_type: string
  readable_type: string
  title: string
  body: string
  html_url: string
  distance: number
  relevance: number
} & Partial<AssetStatus> &
  Partial<ModuleSequence>

export type IndexProgress = {
  progress: number
  status: string
}

export type ModuleSequence = {
  modules: Module[]
}

export type Module = {
  id: number
  name: string
  position: number
  prerequisite_module_ids: number[]
  published: boolean
  items_url: string
}

export type AssetStatus = {
  due_date: string | null
  published: boolean
}

export type WikiPage = {
  id: string
  published: boolean
}

export type DiscussionTopic = {
  id: string
  published: boolean
  assignment: Assignment
}

export type SegmentRecord = {
  segments: string[]
  segementIndex: number
  concentration: number
  concatSegment: string
}
