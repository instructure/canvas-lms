/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {arrayOf, bool, shape, string} from 'prop-types'

const NotificationShape = shape({
  _id: string,
  category: string,
  categoryDisplayName: string,
  name: string,
})

const NotificationPolicyShape = shape({
  communicationChannelId: string,
  frequency: string,
  notification: NotificationShape,
})

const ChannelShape = shape({
  _id: string,
  path: string,
  pathType: string,
  notificationPolicies: arrayOf(NotificationPolicyShape),
  notificationPolicyOverrides: arrayOf(NotificationPolicyShape),
})

export const NotificationPreferencesShape = shape({
  sendScoresInEmails: bool,
  channels: arrayOf(ChannelShape),
})

const TermShape = shape({
  _id: string.isRequired,
  name: string.isRequired,
})

const CourseShape = shape({
  _id: string.isRequired,
  name: string.isRequired,
  term: TermShape.isRequired,
})

export const EnrollmentShape = shape({
  course: CourseShape.isRequired,
  type: string.isRequired,
})
