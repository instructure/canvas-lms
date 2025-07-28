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

import {createContext} from 'react'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {CoursePeopleEnv, CoursePeopleContextType} from '../../types'

declare const ENV: GlobalEnv & CoursePeopleEnv

const defaultEnvPermissions = {
  can_read_roster: false,
  can_allow_course_admin_actions: false,
  can_read_prior_roster: false,
  manage_students: false,
  can_view_all_grades: false,
  read_reports: false,
  user_is_instructor: false,
  self_registration: false,
  can_generate_observer_pairing_code: false,
  view_user_logins: false,
  read_sis: false,
  can_manage_differentiation_tags: false,
  allow_assign_to_differentiation_tags: false,
  active_granular_enrollment_permissions: []
}

const defaultEnvCourse = {
  id: '',
  groups_url: '',
  prior_enrollments_url: '',
  interactions_report_url: '',
  user_services_url: '',
  observer_pairing_codes_url: '',
  hideSectionsOnCourseUsersPage: false,
  concluded: false
}

export const getCoursePeopleContext = ({defaultContext = false} = {}): CoursePeopleContextType => {
  const permissions = defaultContext
    ? defaultEnvPermissions
    : {...defaultEnvPermissions, ...ENV.permissions}

  const course = defaultContext
    ? defaultEnvCourse
    : {...defaultEnvCourse, ...ENV.course}

  const currentUserId = ENV.current_user_id
  const allRoles = ENV.ALL_ROLES

  const {
    can_read_roster: canReadRoster,
    can_allow_course_admin_actions: canAllowCourseAdminActions,
    can_read_prior_roster: canReadPriorRoster,
    manage_students: canManageStudents,
    can_view_all_grades: canViewAllGrades,
    read_reports: canReadReports,
    user_is_instructor: userIsInstructor,
    self_registration: selfRegistration,
    can_generate_observer_pairing_code: canGenerateObserverPairingCode,
    view_user_logins: canViewLoginIdColumn,
    read_sis: canViewSisIdColumn,
    can_manage_differentiation_tags: canManageDifferentiationTags,
    allow_assign_to_differentiation_tags: allowAssignToDifferentiationTags,
    active_granular_enrollment_permissions: activeGranularEnrollmentPermissions
  } = permissions

  const {
    id: courseId,
    groups_url: groupsUrl,
    prior_enrollments_url: priorEnrollmentsUrl,
    interactions_report_url: interactionsReportUrl,
    user_services_url: userServicesUrl,
    observer_pairing_codes_url: observerPairingCodesUrl,
    hideSectionsOnCourseUsersPage: hideSectionsOnCourseUsersPage,
    concluded: courseConcluded
  } = course

  return {
    activeGranularEnrollmentPermissions,
    allRoles,
    allowAssignToDifferentiationTags,
    canReadRoster,
    canAllowCourseAdminActions,
    canGenerateObserverPairingCode,
    canManageStudents,
    canManageDifferentiationTags,
    canReadReports,
    canReadPriorRoster,
    canViewAllGrades,
    canViewLoginIdColumn,
    canViewSisIdColumn,
    courseConcluded,
    courseId,
    currentUserId,
    hideSectionsOnCourseUsersPage,
    userIsInstructor,
    selfRegistration,
    observerPairingCodesUrl,
    groupsUrl,
    interactionsReportUrl,
    priorEnrollmentsUrl,
    userServicesUrl,
  }
}

const CoursePeopleContext = createContext<CoursePeopleContextType>(getCoursePeopleContext({defaultContext: true}))

export default CoursePeopleContext
