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

const I18n = useI18nScope('permissions_templates_22')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Students - add'),
      description: I18n.t('Allows user to add students to a course from the account Courses page.'),
    },
    {
      description: I18n.t('Allows user to update a student’s section enrollment or role.'),
    },
    {
      description: I18n.t('Allows user to add students to a course.'),
    },
    {
      title: I18n.t('Students - remove'),
      description: I18n.t('Allows user to remove students from a course.'),
    },
    {
      description: I18n.t('Allows user to remove a student’s section enrollment or role.'),
    },
    {
      description: I18n.t('Allows user to deactivate students in a course.'),
    },
  ],
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add students to a course from the Courses page via email address or login ID even if a student does not already have a Canvas account.'
      ),
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.'),
    },
    {
      description: I18n.t(
        'To access the account Courses page, Courses - view list must be enabled.'
      ),
    },
    {
      title: I18n.t('People (Course)'),
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      ),
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.'),
    },
  ],
  [
    {
      title: I18n.t('Students - add'),
      description: I18n.t('Allows user to add students to a course.'),
    },
    {
      description: I18n.t('Allows user to update a student’s section enrollment or role.'),
    },
    {
      title: I18n.t('Students - remove'),
      description: I18n.t('Allows user to remove students from a course.'),
    },
    {
      description: I18n.t('Allows user to remove a student’s section enrollment or role.'),
    },
    {
      description: I18n.t('Allows user to deactivate students in a course.'),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'If the Open Registration account setting is enabled, users with this permission can add students to a course from the People page via email address or login ID even if a student does not already have a Canvas account.'
      ),
    },
    {
      description: I18n.t('To add a user via SIS ID, SIS Data - manage must also be enabled.'),
    },
    {
      description: I18n.t(
        'If an enrollment is created via SIS, only admins can remove the enrollment from a course.'
      ),
    },
    {
      description: I18n.t('To remove a user via SIS ID, SIS Data - manage must also be enabled.'),
    },
  ]
)
