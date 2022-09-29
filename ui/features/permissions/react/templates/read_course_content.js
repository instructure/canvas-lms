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

const I18n = useI18nScope('permissions_templates_54')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Courses'),
      description: I18n.t('Allows user to view published and unpublished course content.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Undelete Courses)'),
      description: I18n.t(
        'If Courses - manage and Courses - undelete are also enabled, an account-level user will be able to restore deleted courses in Admin Tools.'
      ),
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t('If disabled, user will still have access to Course Settings.'),
    },
    {
      description: I18n.t(
        'User cannot manage individual course content without the appropriate permission for that content item.'
      ),
    },
    {
      description: I18n.t(
        'If course visibility is limited to users enrolled in the course, this permission allows the user to view course content without being enrolled in the course.'
      ),
    },
    {
      title: I18n.t('Gradebook'),
      description: I18n.t('To view the Gradebook, Grades - view all grades must also be enabled.'),
    },
  ],
  [],
  []
)
