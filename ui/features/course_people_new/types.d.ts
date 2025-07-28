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

import {
  ACTIVE_ENROLLMENT,
  INACTIVE_ENROLLMENT,
  PENDING_ENROLLMENT,
  TEACHER_ENROLLMENT,
  STUDENT_ENROLLMENT,
  TA_ENROLLMENT,
  OBSERVER_ENROLLMENT,
  DESIGNER_ENROLLMENT,
  TEACHER_ROLE,
  STUDENT_ROLE,
  TA_ROLE,
  OBSERVER_ROLE,
  DESIGNER_ROLE,
} from './react/util/constants'

interface EnvPermissions {
  can_read_roster: boolean
  can_allow_course_admin_actions: boolean
  can_read_prior_roster: boolean
  manage_students: boolean
  can_view_all_grades: boolean
  read_reports: boolean
  user_is_instructor: boolean
  self_registration: boolean
  can_generate_observer_pairing_code: boolean
  view_user_logins: boolean
  read_sis: boolean
  can_manage_differentiation_tags: boolean
  allow_assign_to_differentiation_tags: boolean
  active_granular_enrollment_permissions: string[]
}

interface EnvCourse {
  id: string
  groups_url: string
  prior_enrollments_url: string
  interactions_report_url: string
  user_services_url: string
  observer_pairing_codes_url: string
  hideSectionsOnCourseUsersPage: boolean
  allowAssignToDifferentiationTags: boolean
  concluded: boolean
}

export type EnrollmentType =
  | typeof TEACHER_ENROLLMENT
  | typeof STUDENT_ENROLLMENT
  | typeof TA_ENROLLMENT
  | typeof OBSERVER_ENROLLMENT
  | typeof DESIGNER_ENROLLMENT

export interface EnvRole {
  addable_by_user: boolean
  base_role_name: EnrollmentType
  count: number
  deleteable_by_user: boolean
  id: string
  label: string
  name: EnrollmentType | string
  plural_label: string
}

export interface CoursePeopleEnv {
  current_user_id: string
  ALL_ROLES: EnvRole[]
  permissions: EnvPermissions
  course: EnvCourse
}

export interface CoursePeopleContextType {
  allRoles: EnvRole[]
  activeGranularEnrollmentPermissions: string[]
  allowAssignToDifferentiationTags: boolean
  canAllowCourseAdminActions: boolean
  canGenerateObserverPairingCode: boolean
  canManageStudents: boolean
  canManageDifferentiationTags: boolean
  canReadPriorRoster: boolean
  canReadReports: boolean
  canReadRoster: boolean
  canViewAllGrades: boolean
  courseId: string
  courseConcluded: boolean
  groupsUrl: string
  interactionsReportUrl: string
  observerPairingCodesUrl: string
  priorEnrollmentsUrl: string
  selfRegistration: boolean
  userIsInstructor: boolean
  userServicesUrl: string
  canViewLoginIdColumn: boolean
  canViewSisIdColumn: boolean
  hideSectionsOnCourseUsersPage: boolean
  currentUserId: string
}

export type EnrollmentState =
  | typeof ACTIVE_ENROLLMENT
  | typeof INACTIVE_ENROLLMENT
  | typeof PENDING_ENROLLMENT

export type Enrollment = {
  _id: string
  type: string
  sisRole: string
  state: EnrollmentState
  lastActivityAt: string | null
  totalActivityTime: number | null
  canBeRemoved: boolean
  htmlUrl: string
  section: {
    _id: string
    name: string
  }
  temporaryEnrollmentSourceUserId: string | null
  associatedUser: {
    _id: string
    name: string
  } | null
}

export type CustomLink = {
  _id: string
  text: string
  url: string
  icon_class: string
}

export type User = {
  _id: string
  name: string
  loginId: string
  avatarUrl: string
  pronouns: string | null
  sisId: string
  enrollments: Enrollment[]
  customLinks: CustomLink[] | null
}

export type SisRole =
  | typeof TEACHER_ROLE
  | typeof STUDENT_ROLE
  | typeof TA_ROLE
  | typeof OBSERVER_ROLE
  | typeof DESIGNER_ROLE

export type SortField =
  | 'name'
  | 'sis_id'
  | 'login_id'
  | 'section_name'
  | 'role'
  | 'last_activity_at'
  | 'total_activity_time'

export type SortDirection = 'asc' | 'desc'

export type TableHeaderSortDirection = 'ascending' | 'descending' | 'none'
