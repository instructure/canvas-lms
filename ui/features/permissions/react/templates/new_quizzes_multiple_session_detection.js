/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {generateActionTemplates} from '../generateActionTemplates'

const I18n = createI18nScope('permissions_templates_82')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('New Quizzes'),
      description: I18n.t(
        'This permission allows users to view multi-session activity information on the activity log and the moderate page.',
      ),
    },
  ],
  [
    {
      title: I18n.t('Account Roles'),
      description: I18n.t(
        'To allow users to view multi-session activity, the "Admin - add/remove permission" and the "Permissions - manage" permission must be enabled for the Quizzes.Next Service.',
      ),
    },
    {
      title: I18n.t('Quiz settings'),
      description: I18n.t(
        'Educators can enable the Detect Multiple Sessions setting on their quizzes to collect multi-session information on student submissions. This permission determines who can view this data in the activity log and moderate page.',
      ),
    },
  ],
  [
    {
      title: I18n.t('New Quizzes'),
      description: I18n.t(
        'This permission allows users to view multi-session activity information on the activity log and the moderate page.',
      ),
    },
  ],
  [
    {
      title: I18n.t('Account Roles'),
      description: I18n.t(
        'To allow users to view multi-session activity, the "Admin - add/remove permission" and the "Permissions - manage" permission must be enabled for the Quizzes.Next Service.',
      ),
    },
    {
      title: I18n.t('Quiz settings'),
      description: I18n.t(
        'Educators can enable the Detect Multiple Sessions setting on their quizzes to collect multi-session information on student submissions. This permission determines who can view this data in the activity log and moderate page.',
      ),
    },
  ],
)
