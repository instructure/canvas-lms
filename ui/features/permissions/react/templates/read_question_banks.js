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

const I18n = useI18nScope('permissions_templates_58')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Question Banks'),
      description: I18n.t(
        'Allows user to view and link questions in a quiz to account-level question banks.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Quizzes and Question Banks'),
      description: I18n.t(
        'To access the Manage Question Banks link in a course Quizzes Index Page, Course content - view and Assignments and Quizzes - manage / edit must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Question Banks'),
      description: I18n.t(
        'Allows user to view and link questions in a quiz to course-level question banks.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to access the Manage Question Banks link on the Quizzes Index Page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('Question Banks (Courses)'),
      description: I18n.t(
        'To fully manage course-level question banks, Assignments and Quizzes - manage / edit permission must also be enabled.'
      ),
    },
  ]
)
