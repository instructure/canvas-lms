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

import {arrayOf, shape, string} from 'prop-types'

const CourseActivitiesShape = shape({
  dueDate: string,
  gradingPolicies: string,
  courseContent: string,
  files: string,
  announcements: string,
  announcementsCreatedByYou: string,
  announcementReply: string,
  grading: string,
  invitation: string,
  allSubmissions: string,
  lateGrading: string,
  submissionComment: string,
  blueprint: string
})

const DiscussionsShape = shape({
  discussion: string,
  discussionEntry: string
})

const ConversationsShape = shape({
  addedToConversation: string,
  conversationMessage: string,
  conversationCreated: string
})

const SchedulingShape = shape({
  studentAppointmentSignups: string,
  appointmentSignups: string,
  appointmentCancelations: string,
  appointmentAvailability: string,
  calendar: string
})

const GroupsShape = shape({
  membershipUpdate: string
})

const ConferencesShape = shape({
  recordingReady: string
})

const AlertsShape = shape({
  other: string,
  contentLinkError: string,
  accountNotification: string
})

const ChannelShape = shape({
  path: string,
  pathType: string,
  courseActivities: CourseActivitiesShape,
  discussions: DiscussionsShape,
  conversations: ConversationsShape,
  scheduling: SchedulingShape,
  groups: GroupsShape,
  conferences: ConferencesShape,
  alerts: AlertsShape
})

const NotificationPreferencesShape = shape({
  channels: arrayOf(ChannelShape)
})

export default NotificationPreferencesShape
