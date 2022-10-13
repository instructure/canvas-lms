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

const I18n = useI18nScope('permissions_templates_75')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Statistics'),
      description: I18n.t('Allows admin user to view account statistics.'),
    },
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t('Allows user to generate login/logout activity report in Admin Tools.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Logging tab)'),
      description: I18n.t(
        'If Statistics - view or Users - manage login details is enabled, the user will be able to generate login/logout activity in Admin Tools. To hide the login/logout activity option in Admin Tools, both of these permissions need to be disabled.'
      ),
    },
    {
      title: I18n.t('People (Account)'),
      description: I18n.t('To view user page views, Users - view list must also be enabled.'),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.'),
    },
  ],
  [],
  []
)
