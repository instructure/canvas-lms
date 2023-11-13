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

export interface Course {
  readonly id: string
  readonly name: string
  readonly workflow_state: string
  readonly enrollments: Enrollment[]
  readonly sections: Section[]
}

export interface Section {
  readonly course_section_id: string
  readonly course_id: string
  readonly id: string
  readonly name: string
  readonly enrollment_role: string
}

export interface Role {
  readonly id: string
  readonly role: string
  readonly label: string
  readonly base_role_name: string
}

export interface Enrollment {
  readonly id: number
  readonly course_id: number
  readonly user: User
  readonly start_at: string | null
  readonly end_at: string | null
  readonly role_id: string
  readonly type: string
  readonly temporary_enrollment_provider?: User
  readonly temporary_enrollment_pairing_id: number
  readonly temporary_enrollment_source_user_id: number
}

export const PROVIDER = 'provider' as const
export const RECIPIENT = 'recipient' as const

export type EnrollmentType = typeof PROVIDER | typeof RECIPIENT | null

export interface User {
  readonly email?: string | null
  readonly login_id?: string | null
  readonly avatar_url?: string
  readonly id: string
  readonly name: string
  readonly sis_user_id?: string | null
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
  readonly canEdit: boolean
  readonly canAdd: boolean
  readonly canDelete: boolean
}
