/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

const I18n = createI18nScope('permissions_templates_manage_account_calendar')

export const template = generateActionTemplates(
  [
    {
      title: I18n.t('Account Calendars - add / edit / delete events'),
      description: I18n.t('Allows user to add, edit, and delete events in account calendars.'),
    },
    {
      title: I18n.t('Account Calendars - change visibility'),
      description: I18n.t('Allows user to change visibility of account calendars.'),
    },
  ],
  [
    {
      title: I18n.t('Account Calendars'),
      description: I18n.t(
        'Even with the Account Calendars - add / edit / delete events permission enabled, events can only be created in account calendars that are visible.',
      ),
    },
  ],
  [],
  [],
)
