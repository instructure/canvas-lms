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

const I18n = useI18nScope('permissions_templates_73')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Admin Tools (Notifications tab)'),
      description: I18n.t('Allows user to access the View Notifications tab in Admin Tools.'),
    },
  ],
  [
    {
      title: I18n.t('Admin Tools (Notifications tab)'),
      description: I18n.t(
        'To search and view notifications for a user, Users - view must also be enabled.'
      ),
    },
    {
      title: I18n.t('Subaccounts'),
      description: I18n.t('Not available at the subaccount level.'),
    },
  ]
)
