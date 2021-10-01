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

import I18n from 'i18n!permissions_templates_28'
import {generateActionTemplates} from '../generateActionTemplates'

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Courses (Account)'),
      description: I18n.t('Allows user to add new courses to an account.')
    }
  ][
    ({
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'To allow other users to create courses in an account, select the appropriate user role in the Account Settings page: teachers, students, and/or users with no enrollments.'
      )
    },
    {
      description: I18n.t(
        'If this permission is enabled and Courses - view list is disabled, users can add a new course with the Add a New Course button in Account Settings.'
      )
    })
  ],
  [],
  []
)
