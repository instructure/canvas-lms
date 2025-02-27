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

import {PENDING_ENROLLMENT, INACTIVE_ENROLLMENT, ACTIVE_ENROLLMENT} from './util/constants'
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
  COURSE_ROOT_URL: string
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
  courseRootUrl: string
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
}

export type EnrollmentState = typeof PENDING_ENROLLMENT | typeof INACTIVE_ENROLLMENT | typeof ACTIVE_ENROLLMENT | undefined

export type Enrollment = {
  id: string
  name: string
  role: string
  type: string
  last_activity: string | null
  total_activity?: number
  can_be_removed?: boolean
  enrollment_state: EnrollmentState
  temporary_enrollment_source_user_id?: string
  associatedUser?: {
    id: string
    name: string
  }
}

export type CustomLink = {
  id: string
  text: string
  url: string
  icon_class: string
}

export type User = {
  id: string
  short_name: string
  login_id: string
  avatar_url: string
  pronouns?: string
  sis_user_id: string
  last_login: string
  enrollments: Enrollment[]
  custom_links?: CustomLink[]
}
