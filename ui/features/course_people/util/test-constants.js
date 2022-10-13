/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {OBSERVER_ENROLLMENT, TEACHER_ENROLLMENT} from './constants'
import {mockEnrollment} from '../graphql/Mocks'

/* ****************************************************************************************************************** */
//  Mock User Constants
/* ****************************************************************************************************************** */

export const DESIGNER_1 = {
  name: 'Designer 1',
  _id: '10',
  sisId: 'Designer1-SIS-ID',
  loginId: 'Designer1@instructure.com',
  enrollmentType: 'DesignerEnrollment',
  sisRole: 'designer',
}

export const OBSERVER_1 = {
  name: 'Observer 1',
  _id: '40',
  sisId: 'Observer1-SIS-ID',
  loginId: 'Observer1@instructure.com',
  enrollmentType: OBSERVER_ENROLLMENT,
  sisRole: 'observer',
  additionalEnrollments: [
    mockEnrollment({
      _id: '40',
      associatedUserID: '123',
      associatedUserName: 'Observed Student 1',
    }),
    mockEnrollment({
      _id: '40',
      associatedUserID: '124',
      associatedUserName: 'Observed Student 2',
    }),
  ],
}

export const STUDENT_1 = {
  name: 'Student 1',
  _id: '31',
  pronouns: 'They/Them',
  sisId: 'Student1-SIS-ID',
  loginId: 'Student1@instructure.com',
  lastActivityAt: '2021-11-04T09:54:01-06:00',
  totalActivityTime: 90,
}

export const STUDENT_2 = {
  name: 'Student 2',
  _id: '32',
  avatarUrl: 'https://gravatar.com/avatar/52c160622b09015c70fa0f4c25de6cca?s=200&d=identicon&r=pg',
  sisId: 'Student2-SIS-ID',
  loginId: 'Student2@instructure.com',
  enrollmentStatus: 'invited',
}

export const STUDENT_3 = {
  name: 'Student 3',
  _id: '33',
  sisId: 'Student3-SIS-ID',
  loginId: 'Student3@instructure.com',
  enrollmentStatus: 'inactive',
}

export const TEACHER_1 = {
  name: 'Teacher 1',
  _id: '1',
  avatarUrl: 'https://gravatar.com/avatar/589417b6e62ff03d0aab2179d7b05ab7?s=200&d=identicon&r=pg',
  pronouns: 'He/Him',
  sisId: 'Teacher1-SIS-ID',
  loginId: 'teacher1@instructure.com',
  enrollmentType: TEACHER_ENROLLMENT,
  sisRole: 'teacher',
  lastActivityAt: '2022-07-27T10:21:33-06:00',
  totalActivityTime: 60708,
}

export const TA_1 = {
  name: 'TA 1',
  _id: '22',
  pronouns: 'She/Her',
  sisId: 'TA1-SIS-ID',
  loginId: 'TA1@instructure.com',
  enrollmentType: 'TaEnrollment',
  sisRole: 'ta',
  lastActivityAt: '2022-08-16T14:08:13-06:00',
  totalActivityTime: 407,
}

/* ****************************************************************************************************************** */
//  Regex Constants
/* ****************************************************************************************************************** */

export const DATETIME_PATTERN = new RegExp(
  /^[a-z]+ [0-3]?[0-9][, [0-9]*]? at [1]?[0-9]:[0-5][0-9](am|pm)$/, // Apr 16, 2021 at 12:34pm
  'i'
)

export const STOPWATCH_PATTERN = new RegExp(/^[0-9]+(:[0-5][0-9]){1,2}$/) // 00:00 or 00:00:00

/* ****************************************************************************************************************** */
//  window.ENV Constants
/* ****************************************************************************************************************** */

export const SITE_ADMIN_ENV = {
  course: {
    id: '1',
    hideSectionsOnCourseUsersPage: false,
  },
  current_user: {id: '999'},
  permissions: {
    view_user_logins: true,
    read_sis: true,
    read_reports: true,
    can_allow_admin_actions: true,
    manage_admin_users: true,
    manage_students: true,
  },
}
