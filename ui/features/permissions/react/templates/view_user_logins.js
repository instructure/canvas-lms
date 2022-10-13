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

const I18n = useI18nScope('permissions_templates_76')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Account, Course)'),
      description: I18n.t(
        'Allows user to search for other users by Login ID in the account People page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People (Account, Course)'),
      description: I18n.t('To access the People page, Users - view list must be enabled.'),
    },
    {
      description: I18n.t(
        'If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs.'
      ),
    },
    {
      description: I18n.t(
        'To view login IDs, Users - allow administrative actions in courses must also be enabled.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to search for other users by Login ID in the course People page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t('To access the People page, Users - view list must be enabled.'),
    },
    {
      description: I18n.t(
        'If this permission is enabled, and if Users - view primary email address is disabled, users will see email addresses used as login IDs.'
      ),
    },
    {
      description: I18n.t(
        'To view login IDs, Users - allow administrative actions in courses must also be enabled.'
      ),
    },
  ]
)
