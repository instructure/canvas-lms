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

const I18n = useI18nScope('permissions_templates_55')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'Allows user to filter for Blueprint courses as the account level. Allows user to add associated courses.'
      ),
    },
    {
      title: I18n.t('Courses'),
      description: I18n.t('Allows user to see the list of courses in the account.'),
    },
  ],
  [
    {
      title: I18n.t('Account Settings'),
      description: I18n.t(
        'If this permission is disabled and Courses - add is enabled, users can add a new course with the Add a New Course button in Account Settings.'
      ),
    },
    {
      title: I18n.t('Blueprint Courses'),
      description: I18n.t(
        'To add associated courses, Blueprint Courses - add / edit / associate / delete and Courses - add must also be enabled.'
      ),
    },
    {
      title: I18n.t('Statistics'),
      description: I18n.t(
        'Allows user to see the list of recently started and ended courses in account statistics.'
      ),
    },
  ],
  [],
  []
)
