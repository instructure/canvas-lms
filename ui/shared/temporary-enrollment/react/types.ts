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

export const ITEMS_PER_PAGE = 100
export const MAX_ALLOWED_COURSES_PER_PAGE = 50

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
  role?: string
  label: string
  base_role_name: string
}

export interface RoleChoice {
  id: string
  name: string
}

export interface Enrollment {
  id: string
  user_id?: string
  course_id: string
  course_section_id?: string
  user: User
  start_at: string | null
  end_at: string | null
  role_id: string
  type: string
  temporary_enrollment_provider?: User
  temporary_enrollment_pairing_id: number
  temporary_enrollment_source_user_id: number
}

export const PROVIDER = 'provider' as const
export const RECIPIENT = 'recipient' as const

export type EnrollmentType = typeof PROVIDER | typeof RECIPIENT | null

export interface User {
  email?: string | null
  login_id?: string | null
  avatar_url?: string
  id: string
  name: string
  sis_user_id?: string | null
}

export const EMPTY_USER: User = {
  email: null,
  login_id: null,
  avatar_url: '',
  id: '',
  name: '',
  sis_user_id: null,
}

export interface TempEnrollPermissions {
  canEdit: boolean
  canAdd: boolean
  canDelete: boolean
}

export interface Permissions {
  teacher: boolean
  ta: boolean
  student: boolean
  observer: boolean
  designer: boolean
}

export interface SelectedEnrollment {
  course: string
  section: string
}

export interface TemporaryEnrollmentPairing {
  id: string
}
