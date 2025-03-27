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

export interface DifferentiationTagCategory {
  id: number
  name: string
  groups?: DifferentiationTagGroup[]
}

export interface DifferentiationTagGroup {
  id: number
  name: string
  members_count: number
}

export type ModalMode = 'create' | 'edit'
export type ModalTagMode = 'single' | 'multi'

export interface Course {
  readonly id: string
}

export interface UserTags {
  id: number
  name: string
  groupCategoryName: string
  isSingleTag: boolean
}