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
export interface GradingSchemeTemplate {
  title: string
  data: GradingSchemeDataRow[]
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
}

export interface GradingSchemeUpdateRequest {
  id: string
  title: string
  data: GradingSchemeDataRow[]
}

export interface GradingSchemeDataRow {
  name: string
  value: number
}

export interface GradingSchemeSummary {
  title: string
  id: string
}
