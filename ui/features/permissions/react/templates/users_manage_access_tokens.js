/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const I18n = createI18nScope('permissions_templates_users_manage_access_tokens')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Access Tokens - create / update'),
      description: I18n.t('Allows user to create access tokens on behalf of another user.'),
    },
    {
      description: I18n.t('Allows user to update access tokens on behalf of another user.'),
    },
    {
      description: I18n.t('Allows user to regenerate access tokens on behalf of another user.'),
    },
    {
      description: I18n.t(
        'Allows user to still create access tokens for themself when the Limit Personal Access Token Creation setting is on.',
      ),
    },
    {
      description: I18n.t(
        'Allows user to still update their access tokens when the Limit Personal Access Token Creation setting is on.',
      ),
    },
    {
      description: I18n.t(
        'Allows user to still regenerate their access tokens when the Limit Personal Access Token Creation setting is on.',
      ),
    },
    {
      title: I18n.t('Access Tokens - delete'),
      description: I18n.t('Allows user to delete access tokens on behalf of another user.'),
    },
  ],
  [],
  [],
  [],
)
