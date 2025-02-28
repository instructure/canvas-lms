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
  STUDENT_ENROLLMENT,
  ACTIVE_ENROLLMENT,
  STUDENT_ROLE,
} from '../util/constants'

export const mockUser = ({
  userId = '1',
  userName = 'John Doe',
  sisId = 'sis_1',
  avatarUrl = 'https://example.com/avatar.jpg',
  pronouns = null,
  loginId = 'lid_1',
  firstEnrollment = mockEnrollment(),
  otherEnrollments = [],
  customLinks = [],
} = {}) => ({
  _id: userId,
  name: userName ? userName : `user-${userId}`,
  sisId,
  pronouns,
  loginId,
  avatarUrl,
  customLinks,
  enrollments: [
    firstEnrollment,
    ...otherEnrollments
  ],
})

export const mockEnrollment = ({
  courseId = '1',
  enrollmentId = '1',
  enrollmentType = STUDENT_ENROLLMENT,
  enrollmentState = ACTIVE_ENROLLMENT,
  lastActivityAt = '2025-02-19T08:03:27-06:00',
  totalActivityTime = 0,
  canBeRemoved = true,
  sisRole = STUDENT_ROLE,
  htmlUrl = 'https://example.com',
  hasAssociatedUser = false,
  associatedUserId = '9',
  associatedUserName = 'Jane Doe',
  isTemporaryEnrollment = false,
  temporaryEnrollmentSourceUserId = '5',
  sectionId= '1',
  sectionName = 'Section 1'
} = {}) => ({
  _id: enrollmentId,
  type: enrollmentType,
  state: enrollmentState,
  lastActivityAt,
  totalActivityTime:
  totalActivityTime,
  canBeRemoved,
  sisRole,
  htmlUrl,
  temporaryEnrollmentSourceUserId: isTemporaryEnrollment
    ? temporaryEnrollmentSourceUserId
    : null,
  associatedUser: hasAssociatedUser
    ? {
        _id: associatedUserId,
        name: associatedUserName
      }
    : null,
  section: {
    _id: sectionId,
    name: sectionName
  },
})
