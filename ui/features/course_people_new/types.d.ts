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
  PENDING_ENROLLMENT
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

export interface CoursePeopleEnv {
  current_user_id: string
  permissions: EnvPermissions
  course: EnvCourse
}

export interface CoursePeopleContextType {
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

export type EnrollmentState = typeof ACTIVE_ENROLLMENT | typeof INACTIVE_ENROLLMENT | typeof PENDING_ENROLLMENT

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
