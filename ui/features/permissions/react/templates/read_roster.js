/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = useI18nScope('permissions_templates_60')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Navigation'),
      description: I18n.t('Allows user to access the People link in Account Navigation.'),
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to view login/logout activity of users in Admin Tools.'),
    },
    {
      description: I18n.t(
        'Allows user to search grade change logs by grader or student in Admin Tools.'
      ),
    },
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to differentiate assignments to individual students.'),
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view and add users in a collaboration.'),
    },
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'Allows user to send a message in Conversations without selecting a course.'
      ),
    },
    {
      title: I18n.t('Course Navigation'),
      description: I18n.t('Allows user to view the People link in Course Navigation.'),
    },
    {
      title: I18n.t('Groups (Course)'),
      description: I18n.t('Allows user to view groups in a course.'),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('Allows user to view list of users in the account.'),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view list of users in the course People page.'),
    },
    {
      description: I18n.t(
        'Allows user to view the Prior Enrollments button in the course People page.'
      ),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.'),
    },
  ],
  [
    {
      title: I18n.t('Account Groups'),
      description: I18n.t('To view account-level groups, Groups - manage must also be enabled.'),
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'To generate login/logout activity in Admin Tools, Users - manage login details or Statistics - view must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To generate grade change logs in Admin Tools, Grades - view change logs must also be enabled.'
      ),
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t('To add groups, Groups - add must also be enabled.'),
    },
    {
      description: I18n.t('To delete groups, Groups - delete must also be enabled.'),
    },
    {
      description: I18n.t('To edit groups, Groups - manage must also be enabled.'),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To edit user details, modify login details, or change user passwords, Users - manage login details must also be enabled.'
      ),
    },
    {
      description: I18n.t('To view user page views, Statistics - view must also be enabled.'),
    },
    {
      description: I18n.t('To act as other users, Users - act as must also be enabled.'),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To edit a user’s section, the appropriate Users permission (e.g. Users - Teachers), Users - allow administrative actions in courses, and Conversations - send to individual course members must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Assignments'),
      description: I18n.t('Allows user to differentiate assignments to individual students.'),
    },
    {
      title: I18n.t('Collaborations'),
      description: I18n.t('Allows user to view and add users in a collaboration.'),
    },
    {
      title: I18n.t('Course'),
      description: I18n.t('Navigation Allows user to view the People link in Course Navigation.'),
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t('Allows user to view groups in a course.'),
    },
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view list of users in the course People page.'),
    },
    {
      description: I18n.t(
        'Allows user to view the Prior Enrollments button in the course People page.'
      ),
    },
    {
      title: I18n.t('Settings'),
      description: I18n.t('Allows user to view enrollments on the Sections tab.'),
    },
  ],
  [
    {
      title: I18n.t('Conversations'),
      description: I18n.t(
        'To send a message to an individual user, Conversations - send messages to individual course members must also be enabled.'
      ),
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t('To add groups, Groups - add must also be enabled.'),
    },
    {
      description: I18n.t('To delete groups, Groups - delete must also be enabled.'),
    },
    {
      description: I18n.t('To edit groups, Groups - manage must also be enabled.'),
    },
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      description: I18n.t(
        'To edit a user’s section, Users - allow administrative actions in courses and Users - view list must also be enabled.'
      ),
    },
  ]
)
