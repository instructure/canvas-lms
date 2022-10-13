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

const I18n = useI18nScope('permissions_templates_56')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t(
        'Allows user to search for account users via primary email address in the account People page.'
      ),
    },
    {
      description: I18n.t(
        'Allows user to search for other users via primary email address in a course People page.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('To view the account People page, Users - view list must be enabled.'),
    },
    {
      description: I18n.t(
        'If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.'
      ),
    },
  ],
  [
    {
      title: I18n.t('People'),
      description: I18n.t(
        'Allows user to search for other users via primary email addresses in the People page.'
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
        'If this permission is disabled, and Users - view login IDs is enabled, users will still see email addresses used as login IDs.'
      ),
    },
  ]
)
