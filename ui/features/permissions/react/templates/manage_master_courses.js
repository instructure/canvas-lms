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

const I18n = useI18nScope('permissions_templates_36')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t('Allows user to designate a course as a Blueprint Course.'),
    },
    {
      description: I18n.t('Allows user to manage Blueprint Course settings in Course Settings.'),
    },
    {
      description: I18n.t('Allows user to add and remove associated courses.'),
    },
    {
      description: I18n.t(
        'Allows user to edit lock settings on individual assignments, pages, or discussions.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Course roles can only manage Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.'
      ),
    },
    {
      description: I18n.t(
        'To manage associated courses, Courses - view list and Courses - add must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To edit lock settings on files, Courses - manage and Course Files - edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To edit lock settings on quizzes, Courses - manage and Assignments and Quizzes - manage / edit must also be enabled.'
      ),
    },
    {
      description: I18n.t(
        'To manage lock settings for object types, Courses - manage must also be enabled.'
      ),
    },
  ],
  [],
  []
)
