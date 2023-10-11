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

export const MODULE_NAME = 'TempEnroll'

export interface Course {
  id: string
  name: string
  workflow_state: string
  enrollments: Enrollment[]
  sections: Section[]
}

export interface Section {
  course_section_id: string
  course_id: string
  id: string
  name: string
  enrollment_role: string
}

export interface Role {
  id: string
  role: string
  label: string
  base_role_name: string
}

export interface Enrollment {
  id: number
  course_id: number
  user: User
  start_at: string | null
  end_at: string | null
  role_id: string
  type: string
}

export const PROVIDER = 'provider' as const
export const RECIPIENT = 'recipient' as const

export type EnrollmentType = typeof PROVIDER | typeof RECIPIENT | null

export interface User {
  id: number
  name: string
}

export interface TempEnrollPermissions {
  canEdit: boolean
  canAdd: boolean
  canDelete: boolean
}
