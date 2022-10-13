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

const I18n = useI18nScope('permissions_templates_45')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view login ID information for students.'),
    },
    {
      description: I18n.t('Allows user to view prior enrollments.'),
    },
    {
      description: I18n.t('Allows user to access a user’s settings menu and user details.'),
    },
    {
      description: I18n.t('Allows user to resend course invitations from the Course People page.'),
    },
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'To add or remove a student to or from a course, the Users - Student permission must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view the list of users in the course, Users - view list must be enabled.'
      ),
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.'),
    },
    {
      description: I18n.t(
        'To edit a student’s section, Conversations - send to individual course members must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view login ID information for students.'),
    },
    {
      description: I18n.t('Allows user to view prior enrollments.'),
    },
    {
      description: I18n.t('Allows user to access a user’s settings menu and user details.'),
    },
    {
      description: I18n.t('Allows user to resend course invitations from the Course People page.'),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'To add or remove a student to or from a course, the Users - Students permissions must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To view the list of users in the course, Users - view list must be enabled.'
      ),
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.'),
    },
    {
      description: I18n.t(
        'To edit a student’s section, Conversations - send to individual course members must also be enabled.'
      ),
    },
  ]
)
