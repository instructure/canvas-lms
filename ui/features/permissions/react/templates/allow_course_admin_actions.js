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

const I18n = useI18nScope('permissions_templates_1')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('Allows user to view login ID information for users.'),
    },
    {
      description: I18n.t('Allows user to view user details for course users.'),
    },
    {
      description: I18n.t('Allows user to edit a user’s section or role (if not added via SIS).'),
    },
  ],
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'To edit user details, modify login details, or change user passwords, Users - manage login details must also be enabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t('To view the People page, Courses - view list must be enabled.'),
    },
    {
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.'),
    },
    {
      description: I18n.t(
        'To edit a user’s section, Conversations - send to individual course members must be enabled.'
      ),
    },
    {
      title: I18n.t('Observers (Course)'),
      description: I18n.t(
        'To link an observer to a student, Users - manage login details and Conversations - send to individual course members must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To generate a pairing code on behalf of a student to share with an observer, Users - Generate observer pairing code for students must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('Allows user to view login ID information for users.'),
    },
    {
      description: I18n.t('Allows user to view user details for course users.'),
    },
    {
      description: I18n.t('Allows user to edit a user’s section or role (if not added via SIS).'),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To view the People page, Courses - view list must be enabled.'),
    },
    {
      description: I18n.t(
        'To add or remove users to a course, the appropriate Users permission must be enabled (e.g. Users - Teachers).'
      ),
    },
    {
      description: I18n.t('To view SIS IDs, SIS Data - read must be enabled.'),
    },
    {
      description: I18n.t(
        'To edit a user’s section, Conversations - send to individual course members must be enabled.'
      ),
    },
    {
      title: I18n.t('Observers'),
      description: I18n.t(
        'To link an observer to a student, Conversations - send to individual course members must be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To generate a pairing code on behalf of a student to share with an observer, Users - Generate observer pairing code for students must also be enabled.'
      ),
    },
  ]
)
