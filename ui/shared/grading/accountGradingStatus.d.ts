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

export type GradeStatusType = 'standard' | 'custom' | 'new'

export type GradeStatus = {
  id: string
  name: string
  color: string
  isNew?: boolean
  appliesToSubmissions?: boolean
  appliesToFinalGrade?: boolean
  allowFinalGradeValue?: boolean
}

export type GradeStatusUnderscore = {
  id: string
  name: string
  color: string
  applies_to_submissions?: boolean
  applies_to_final_grade?: boolean
  allow_final_grade_value?: boolean
}

export type StandardStatusAllowedName =
  | 'late'
  | 'missing'
  | 'resubmitted'
  | 'dropped'
  | 'excused'
  | 'extended'
