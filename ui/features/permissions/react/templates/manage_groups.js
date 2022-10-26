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

const I18n = useI18nScope('permissions_templates_34')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Groups - add'),
      description: I18n.t('Allows user to create account or course groups.'),
    },
    {
      description: I18n.t('Allows user to add group members to account or course groups.'),
    },
    {
      description: I18n.t('Allows user to add a group for a group assignment in a course.'),
    },
    {
      description: I18n.t('Allows user to create course groups created by students.'),
    },
    {
      description: I18n.t('Allows users to import groups in a course.'),
    },
    {
      title: I18n.t('Groups - delete'),
      description: I18n.t('Allows user to delete account or course groups.'),
    },
    {
      description: I18n.t('Allows user to remove students from account or course groups.'),
    },
    {
      description: I18n.t(
        'Allows user to move group members to another group in an account or course.'
      ),
    },
    {
      description: I18n.t('Allows user to assign a student group leader in an account or course.'),
    },
    {
      title: I18n.t('Groups - manage'),
      description: I18n.t('Allows user to edit account and course groups.'),
    },
    {
      description: I18n.t(
        'Allows user to view the Clone Group Set button for an account or course group.'
      ),
    },
    {
      description: I18n.t('Allows user to randomly assign users to an account or course group.'),
    },
    {
      description: I18n.t('Allows user to add users to an account or course group.'),
    },
    {
      description: I18n.t(
        'Allows user to move group members to another group in an account or course.'
      ),
    },
    {
      description: I18n.t('Allows user to assign a student group leader in an account or course.'),
    },
  ],
  [
    {
      title: I18n.t('Groups - add'),
      description: I18n.t(
        'To add account level groups via CSV, SIS Data - import must also be enabled.'
      ),
    },
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'If this permission is disabled, at the account level, the user cannot view any existing account groups. At the course level, the user can view, but not access, any existing groups, including groups created by students.'
      ),
    },
    {
      description: I18n.t('To view account-level groups, Users - view list must also be enabled.'),
    },
    {
      description: I18n.t(
        'To view all student groups in a course, Groups - view all student groups must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'By default, students can always create groups in a course. To restrict students from creating groups, Courses - manage must be enabled, and the Let students organize their own groups checkbox in Course Settings must not be selected.'
      ),
    },
    {
      description: I18n.t(
        'To access the People page and view course groups, Users - view list must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Groups - add'),
      description: I18n.t('Allows user to create course groups.'),
    },
    {
      description: I18n.t('Allows user to add students to course groups.'),
    },
    {
      description: I18n.t('Allows user to add a group for a group assignment in a course.'),
    },
    {
      description: I18n.t('Allows user to create course groups created by students.'),
    },
    {
      description: I18n.t('Allows users to import groups in a course.'),
    },
    {
      title: I18n.t('Groups - delete'),
      description: I18n.t('Allows user to delete course groups.'),
    },
    {
      description: I18n.t('Allows user to remove group members from course groups.'),
    },
    {
      description: I18n.t('Allows user to move group members to another group in a course.'),
    },
    {
      description: I18n.t('Allows user to assign a student group leader in a course.'),
    },
    {
      title: I18n.t('Groups - manage'),
      description: I18n.t('Allows user to edit course groups.'),
    },
    {
      description: I18n.t('Allows user to view the Clone Group Set button for a course group.'),
    },
    {
      description: I18n.t('Allows user to randomly assign users to a course group.'),
    },
    {
      description: I18n.t('Allows user to add users to a course group.'),
    },
    {
      description: I18n.t('Allows user to move group members to another group in a course.'),
    },
    {
      description: I18n.t('Allows user to assign a student group leader in a course.'),
    },
  ],
  [
    {
      title: I18n.t('Groups'),
      description: I18n.t(
        'To view all student groups in a course, Groups - view all student groups must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'By default, students can always create groups in a course. To restrict students from creating groups, Courses - manage must be enabled, and the Let students organize their own groups checkbox in Course Settings must not be selected.'
      ),
    },
    {
      description: I18n.t(
        'To access the People page and view course groups, Users - view list must also be enabled.'
      ),
    },
  ]
)
