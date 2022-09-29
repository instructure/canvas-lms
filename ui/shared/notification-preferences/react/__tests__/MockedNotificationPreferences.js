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
const mockedNotificationPreferences = overrides => ({
  sendScoresInEmails: true,
  channels: [
    {
      _id: '1',
      path: 'test@test.com',
      pathType: 'email',
      notificationPolicies: [
        {
          communicationChannelId: '1',
          frequency: 'daily',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Override Changed',
            _id: '3',
          },
        },
        {
          communicationChannelId: '1',
          frequency: 'daily',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Changed',
            _id: '36',
          },
        },
        {
          communicationChannelId: '1',
          frequency: 'daily',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Created',
            _id: '37',
          },
        },
        {
          communicationChannelId: '1',
          frequency: 'immediately',
          notification: {
            category: 'Grading',
            categoryDisplayName: 'Grading',
            categoryDescription: 'Grading description',
            name: 'Quiz Regrade Finished',
            _id: '5',
          },
        },
        {
          communicationChannelId: '1',
          frequency: 'never',
          notification: {
            category: 'All Submissions',
            categoryDisplayName: 'All Submissions',
            categoryDescription: 'All submissions description',
            name: 'Submission Needs Grading',
            _id: '4',
          },
        },
        {
          communicationChannelId: '1',
          frequency: 'immediately',
          notification: {
            _id: '112',
            category: 'ReportedReply',
            categoryDescription: 'New reported reply in a Discussion',
            categoryDisplayName: 'Reported Reply',
            name: 'Reported Reply',
          },
        },
      ],
      notificationPolicyOverrides: [
        {
          communicationChannelId: '1',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Override Changed',
            _id: '3',
          },
        },
      ],
    },
    {
      _id: '17',
      path: '1238675309@messaging.sprintpcs.com',
      pathType: 'sms',
      notificationPolicies: [
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Override Changed',
            _id: '3',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Changed',
            _id: '36',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Created',
            _id: '37',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'immediately',
          notification: {
            category: 'Grading',
            categoryDisplayName: 'Grading',
            categoryDescription: 'Grading description',
            name: 'Quiz Regrade Finished',
            _id: '5',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'All Submissions',
            categoryDisplayName: 'All Submissions',
            categoryDescription: 'All submissions description',
            name: 'Submission Needs Grading',
            _id: '4',
          },
        },
      ],
      notificationPolicyOverrides: null,
    },
    {
      _id: '27',
      path: 'push',
      pathType: 'push',
      notificationPolicies: [
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Override Changed',
            _id: '3',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Due Date Changed',
            _id: '36',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'Due Date',
            categoryDisplayName: 'Due Date',
            categoryDescription: 'Due date description',
            name: 'Assignment Created',
            _id: '37',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'immediately',
          notification: {
            category: 'Grading',
            categoryDisplayName: 'Grading',
            categoryDescription: 'Grading description',
            name: 'Quiz Regrade Finished',
            _id: '5',
          },
        },
        {
          communicationChannelId: '17',
          frequency: 'never',
          notification: {
            category: 'All Submissions',
            categoryDisplayName: 'All Submissions',
            categoryDescription: 'All submissions description',
            name: 'Submission Needs Grading',
            _id: '4',
          },
        },
      ],
      notificationPolicyOverrides: null,
    },
  ],
  ...overrides,
})

export default mockedNotificationPreferences
