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

import {GradingSchemeDataRow} from '@instructure/grading-utils'

export interface GradingSchemeTemplate {
  title: string
  data: GradingSchemeDataRow[]
  scaling_factor: number
  points_based: boolean
}

export type UsedLocation = {
  id: string
  name: string
  'concluded?'?: boolean
  assignments: {
    id: string
    title: string
  }[]
  with_assignments?: boolean
  assignments_next_page?: string
  assignments_last_page?: boolean
}

export type AssignmentUsedLocation = {
  id: string
  title: string
}

export type AccountUsedLocation = {
  id: string
  name: string
}

export interface GradingScheme {
  id: string
  title: string
  data: GradingSchemeDataRow[]
  context_type: 'Account' | 'Course'
  context_id: string
  context_name: string
  permissions: {manage: boolean}
  assessed_assignment: boolean
  scaling_factor: number
  points_based: boolean
  used_locations?: UsedLocation[]
  account_used_locations?: AccountUsedLocation[]
  workflow_state: 'active' | 'archived' | 'deleted'
  used_as_default: boolean
}

export interface GradingSchemeUpdateRequest {
  id: string
  title: string
  data: GradingSchemeDataRow[]
  scaling_factor: number
  points_based: boolean
}

export interface GradingSchemeSummary {
  title: string
  id: string
  context_type: 'Account' | 'Course'
}

export interface GradingSchemeCardData {
  editing: boolean
  gradingScheme: GradingScheme
}
