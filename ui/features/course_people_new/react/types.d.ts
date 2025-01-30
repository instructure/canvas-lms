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

interface CoursePeoplePermissions {
  can_read_roster: boolean
  can_allow_course_admin_actions: boolean
  can_read_prior_roster: boolean
  manage_students: boolean
  can_view_all_grades: boolean
  read_reports: boolean
  user_is_instructor: boolean
  self_registration: boolean
  can_generate_observer_pairing_code: boolean
}

interface CoursePeopleUrls {
  groups_url: string
  prior_enrollments_url: string
  interactions_report_url: string
  user_services_url: string
  observer_pairing_codes_url: string
}

export interface CoursePeopleEnv {
  permissions: CoursePeoplePermissions
  course: CoursePeopleUrls
}

export interface CoursePeopleContextType {
  canReadRoster: boolean
  canAllowCourseAdminActions: boolean
  canReadPriorRoster: boolean
  canManageStudents: boolean
  canViewAllGrades: boolean
  canReadReports: boolean
  userIsInstructor: boolean
  selfRegistration: boolean
  canGenerateObserverPairingCode: boolean
  groupsUrl: string
  priorEnrollmentsUrl: string
  interactionsReportUrl: string
  userServicesUrl: string
  observerPairingCodesUrl: string
}
