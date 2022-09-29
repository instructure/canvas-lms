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

import {ROSTER_QUERY} from './Queries'

export const mockUser = ({
  courseID = '1',
  name = 'user',
  _id = '1',
  sisId = null,
  avatarUrl = null,
  pronouns = null,
  loginId = null,
  enrollmentType = 'StudentEnrollment',
  enrollmentStatus = 'active',
  lastActivityAt = '2022-07-07T10:01:14-06:00',
  totalActivityTime = 0,
  canBeRemoved = true,
  sisRole = 'student',
  sectionID = '1',
  sectionName = 'Section 1',
  additionalEnrollments = [],
} = {}) => ({
  name,
  _id,
  id: Buffer.from(`User-${_id}`).toString('base64'),
  sisId,
  avatarUrl,
  pronouns,
  loginId,
  __typename: 'user',
  enrollments: [
    {
      id: Buffer.from(`Enrollment-${_id}`).toString('base64'),
      type: enrollmentType,
      state: enrollmentStatus,
      lastActivityAt,
      htmlUrl: `http://test.host/courses/${courseID}/users/${_id}`,
      totalActivityTime,
      canBeRemoved,
      sisRole,
      associatedUser: null, // always null for user's own enrollment
      __typename: 'enrollment',
      section: {
        _id: sectionID,
        id: Buffer.from(`Section-${sectionID}`).toString('base64'),
        name: sectionName,
        __typename: 'section',
      },
    },
    ...additionalEnrollments,
  ],
})

export const mockEnrollment = ({
  courseID = '1',
  _id = '1',
  enrollmentType = 'ObserverEnrollment',
  enrollmentStatus = 'active',
  lastActivityAt = '2022-07-07T10:01:14-06:00',
  totalActivityTime = 0,
  canBeRemoved = true,
  sisRole = 'observer',
  associatedUserID = '2',
  associatedUserName = 'Test User',
  sectionID = '1',
  sectionName = 'Section 1',
} = {}) => ({
  id: Buffer.from(`Enrollment-${associatedUserID}`).toString('base64'),
  type: enrollmentType,
  state: enrollmentStatus,
  lastActivityAt,
  htmlUrl: `http://test.host/courses/${courseID}/users/${_id}`,
  totalActivityTime,
  canBeRemoved,
  sisRole,
  __typename: 'enrollment',
  associatedUser: {
    _id: associatedUserID,
    id: Buffer.from(`User-${associatedUserID}`).toString('base64'),
    name: associatedUserName,
    __typename: 'associatedUser',
  },
  section: {
    _id: sectionID,
    id: Buffer.from(`Section-${sectionID}`).toString('base64'),
    name: sectionName,
    __typename: 'section',
  },
})

export const getRosterQueryMock = ({mockUsers = [], courseID = '1', shouldError = false} = {}) => [
  {
    request: {
      query: ROSTER_QUERY,
      variables: {
        courseID,
      },
    },
    result: {
      data: {
        course: {
          usersConnection: {
            nodes: [...mockUsers],
            __typename: 'usersConnection',
          },
          __typename: 'course',
        },
      },
    },
    ...(shouldError && {error: new Error('graphql error')}),
  },
]
