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
import type {CoursePeopleEnv, CoursePeopleContextType} from '../types.d'

declare const ENV: GlobalEnv & CoursePeopleEnv

const defaultCoursePeoplePermissions = {
  can_read_roster: false,
  can_allow_course_admin_actions: false,
  can_read_prior_roster: false,
  manage_students: false,
  can_view_all_grades: false,
  read_reports: false,
  user_is_instructor: false,
  self_registration: false,
  can_generate_observer_pairing_code: false,
}

const defaultCoursePeopleUrls = {
  groups_url: '',
  prior_enrollments_url: '',
  interactions_report_url: '',
  user_services_url: '',
  observer_pairing_codes_url: ''
}

export const getCoursePeopleContext = ({defaultContext = false} = {}): CoursePeopleContextType => {
  const permissions = defaultContext
    ? defaultCoursePeoplePermissions
    : {...defaultCoursePeoplePermissions, ...ENV.permissions}

  const course = defaultContext
    ? defaultCoursePeopleUrls
    : {...defaultCoursePeopleUrls, ...ENV.course}

  const {
    can_read_roster: canReadRoster,
    can_allow_course_admin_actions: canAllowCourseAdminActions,
    can_read_prior_roster: canReadPriorRoster,
    manage_students: canManageStudents,
    can_view_all_grades: canViewAllGrades,
    read_reports: canReadReports,
    user_is_instructor: userIsInstructor,
    self_registration: selfRegistration,
    can_generate_observer_pairing_code: canGenerateObserverPairingCode
  } = permissions

  const {
    groups_url: groupsUrl,
    prior_enrollments_url: priorEnrollmentsUrl,
    interactions_report_url: interactionsReportUrl,
    user_services_url: userServicesUrl,
    observer_pairing_codes_url: observerPairingCodesUrl
  } = course

  return {
    canReadRoster,
    canAllowCourseAdminActions,
    canReadPriorRoster,
    canManageStudents,
    canViewAllGrades,
    canReadReports,
    userIsInstructor,
    selfRegistration,
    canGenerateObserverPairingCode,
    groupsUrl,
    priorEnrollmentsUrl,
    interactionsReportUrl,
    userServicesUrl,
    observerPairingCodesUrl,
  }
}

const CoursePeopleContext = createContext<CoursePeopleContextType>(getCoursePeopleContext({defaultContext: true}))

export default CoursePeopleContext
